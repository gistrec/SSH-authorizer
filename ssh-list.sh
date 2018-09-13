#!/bin/sh

# Количиство параметров у скрипта
params_count=$#

# Если параметры есть, то смотрим какой это параметр
if [ $params_count -ge 1 ]
then
	case "$1" in
	-h|-help) echo "Вывести мануал" ;;
	-a|-add) echo "Добавить сервер" ;;
	-d|-delete) echo "Удалить сервер";;
	-i|-install) echo "Установить скрипт" ;;
	*) echo "Неизвестный параметр '$1'";;
	esac
fi
