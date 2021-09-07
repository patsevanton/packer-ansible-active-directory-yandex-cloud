Сборка образа Active Directory c помощью packer и ansible в яндекс-облаке

Source code from https://github.com/yandex-cloud/examples/tree/master/packer-ansible-windows

Установка необходимых пакетов
```
sudo apt update
sudo apt install git jq python3-pip -y
sudo pip3 install ansible
ansible-galaxy collection install ansible.windows
ansible-galaxy install justin_p.pdc
sudo pip3 install pywinrm
```

Установка Packer
Необходимо установить packer по инструкции с официального сайта https://learn.hashicorp.com/tutorials/packer/get-started-install-cli

Установка Yandex.Cloud CLI
https://cloud.yandex.com/en/docs/cli/quickstart#install
```
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

Инициализация Yandex.Cloud CLI
```
yc init
```

Clone repo
```
git clone https://github.com/patsevanton/packer-ansible-active-directory-yandex-cloud.git
cd packer-ansible-active-directory-yandex-cloud
```

Download ConfigureRemotingForAnsible.ps1
```
wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
```

Создайте сервисный аккаунт и передайте его идентификатор в переменную окружения, выполнив команды:
```
yc iam service-account create --name <имя пользователя>
yc iam key create --service-account-name <имя пользователя> -o service-account.json
SERVICE_ACCOUNT_ID=$(yc iam service-account get --name <имя пользователя> --format json | jq -r .id)
```

В документации к Yandex Cloud folder_id описывается как <имя_каталога>.

Получите folder_id из `yc config list`

Назначьте сервисному аккаунту роль admin в каталоге, где будут выполняться операции:
```
yc resource-manager folder add-access-binding <folder_id> --role admin --subject serviceAccount:$SERVICE_ACCOUNT_ID
```

Заполните файл windows-ansible.json
```
    "folder_id": "<folder_id>",
    "service_account_key_file": "service-account.json",
    "password": "<Пароль для Windows>",
```

Запускаем сборку образа
```
packer build windows-ansible.json
```

При сборке образа сначала выполняется скрипты, описанные в user-data:
```
#ps1
net user Administrator {{user `password`}}
ls \"C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\LocalScripts\" | rm
Remove-Item -Path WSMan:\\Localhost\\listener\\listener* -Recurse
Remove-Item -Path Cert:\\LocalMachine\\My\\*
$DnsName = Invoke-RestMethod -Headers @{\"Metadata-Flavor\"=\"Google\"} \"http://169.254.169.254/computeMetadata/v1/instance/hostname\"
$HostName = Invoke-RestMethod -Headers @{\"Metadata-Flavor\"=\"Google\"} \"http://169.254.169.254/computeMetadata/v1/instance/name\"
$Certificate = New-SelfSignedCertificate -CertStoreLocation Cert:\\LocalMachine\\My -DnsName $DnsName -Subject $HostName
New-Item -Path WSMan:\\LocalHost\\Listener -Transport HTTP -Address * -Force
New-Item -Path WSMan:\\LocalHost\\Listener -Transport HTTPS -Address * -Force -HostName $HostName -CertificateThumbPrint $Certificate.Thumbprint
& netsh advfirewall firewall add rule name=\"WINRM-HTTPS-In-TCP\" protocol=TCP dir=in localport=5986 action=allow profile=any
```

Для отладки добавляем конструкцию, подключаемся по RDP и пробуем подключится по ansible напрямую.
```
{
    "type": "shell",
    "inline": [
        "sleep 9999999"
    ]
},
```

Отредатировать файл ansible/inventory. Проверить win_ping.

```
ansible windows -i ansible/inventory -m win_ping
```

Ошибки:

Если не запустить ConfigureRemotingForAnsible.ps1 на Windows, то будет такая ошибка
```
basic: the specified credentials were rejected by the server
```

Если забыли установить "use_proxy" в false, то будет такая ошибка
```
basic: HTTPSConnectionPool(host=''127.0.0.1'', port=5986): Max retries exceeded with url: /wsman (Caused by NewConnectionError(''<urllib3.connection.VerifiedHTTPSConnection object at 0x7f555c2d07c0>: Failed to establish a new connection: [Errno 111] Connection refused''))
```
