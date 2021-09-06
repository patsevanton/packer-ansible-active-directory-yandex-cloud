Сборка образа Active Directory c помощью packer и ansible в яндекс-облаке

Source code from https://github.com/yandex-cloud/examples/tree/master/packer-ansible-windows

Установка необходимых пакетов
```
sudo apt update
sudo apt install git jq python3-pip -y
sudo pip3 install ansible
ansible-galaxy collection install ansible.windows
ansible-galaxy install justin_p.pdc
sudo pip3 install pywinrm pypsrp xmltodict
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

Получите folder_id (<имя_каталога>) из `yc config list`

Назначьте сервисному аккаунту роль admin в каталоге, где будут выполняться операции:
```
yc resource-manager folder add-access-binding <имя_каталога> --role admin --subject serviceAccount:$SERVICE_ACCOUNT_ID
```

Заполните файл windows-ansible.json
```
    "folder_id": "<ваш folder_id/имя_каталога>",
    "service_account_key_file": "service-account.json",
    "password": "Пароль для Windows",
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



Add
```
    {
      "type": "powershell",
      "scripts": [
          "{{template_dir}}/ConfigureRemotingForAnsible.ps1"
      ]
    },
```

For debug:
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

После исправления ошибок протестировать
```
   {
       "type": "ansible",
       "playbook_file": "{{template_dir}}/ansible/packer_active_directory.yml",
       "extra_arguments": [
       	"--tags",
       	"install",
        "--extra-vars", "ansible_shell_type=powershell ansible_shell_executable=None ansible_python_interpreter=/usr/bin/python"
       ],
       "ansible_env_vars": ["ANSIBLE_SSH_ARGS='-o ControlPersist=10m'"]
   },
```
