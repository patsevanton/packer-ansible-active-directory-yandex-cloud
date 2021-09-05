Сборка образа Active Directory c помощью packer и ansible в яндекс-облаке

Source code from https://github.com/yandex-cloud/examples/tree/master/packer-ansible-windows

Установка необходимых пакетов
```
sudo apt update
sudo apt install git jq python3-pip
sudo pip3 install ansible
ansible-galaxy collection install ansible.windows
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
