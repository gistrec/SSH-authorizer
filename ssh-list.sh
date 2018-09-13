#!/bin/bash

# Зависимости
# 1. sshpass

# Выводим сообщение о доступных параметрах
help() {
	echo "-h или -help    вывести этот текст"
	echo "-a или -add     добавить сервер"
	echo "-d или -delete  удалить сервер"
	echo "-i или -install установить данный скрипт"
	exit 0
}

# В функции будем добавлять новый ssh сервер
add() {
	user=$1
	host=$2
	passwd=$3

	echo "Добавление нового сервера"
	echo "User: $user"
	echo "Host: $host"
	echo "Passwd: $passwd"
	read -p "Данные верны (y/n)? " answer

	case $answer in
		# Символы Y,y,Д,д
		[YyДд]*) ;;
		# Энтер
		"") ;;
		# В остальных случаях - выходим из программы
		*) echo "Операция прервана"; exit 1;;
	esac

	server="$user@$host"

	# Проверка на то, что к ssh можно подключиться
	# Выполняем на сервере команду echo 'work'
	response=`sshpass -p "$passwd" ssh -o 'IdentitiesOnly=yes' $server 'echo "work"'`
	if [ "$response" != "work" ]
	then
		echo 'Не удалось подключиться к ssh'
		exit 1
	fi

	# Удаляем преыддущий ключ
	rm ~/.ssh/$server >/dev/null
	# Генерируем ключ
	ssh-keygen -t rsa -q -N '' -f ~/.ssh/$server
	# echo "$result"

	# Перемещаем ключ на удаленный сервер
	sshpass -p "$passwd" scp -o 'IdentitiesOnly=yes' ~/.ssh/$server.pub $server:~
	# Создаем директорию
	sshpass -p "$passwd" ssh -o 'IdentitiesOnly=yes' $server \
	"[ -d ~/.ssh ] || (mkdir ~/.ssh; chmod 711 ~/.ssh) && " \
	"cat ~/$server.pub >> ~/.ssh/authorized_keys && " \
	"chmod 600 ~/.ssh/authorized_keys && " \
	"rm ~/$server.pub"

	ssh-add ~/.ssh/$server 2>/dev/null

	echo 'Сервер успешно добавлен'

	# Добавляем строку с данными о сервере в файл
	echo "$user $host" >> ~/.ssh/ssh-list
}

# В функции будем удалять существующий ssh сервер
delete() {
	echo 'delete'
}

# В функции будем устанавливать этот скрипт
# Т.е. переносить его в /usr/bin/
# И устанавливать нужные права
install() {
	echo 'install'
}

# Добавляет пробелы спереди строки до тех пор, пока
# строка не станет заданной длины
# Входные данные:
#     $1 - строка
#     $2 - заданная длина строки
getFormattedString() {
	length=$(expr length $1)

	need_spaces=$(($2 - $length - 1))

	string=$(printf "%${need_spaces}s" ' ' | sed "s/ / /g")

	echo "${string}${1} "
}

show() {
	echo "╔═════════════════════════════════════════════════╗"
	echo "║          Список доступных ssh серверов          ║"
	echo "╠════╦════════════╦═══════════════════════════════╣"
	echo "║ id ║    user    ║             host              ║"
	echo "╠════╬════════════╬═══════════════════════════════╣"

	id=0

	while read line
	do
		IFS=' ' read -r -a pieces <<< "$line"
		user="${pieces[0]}"
		host="${pieces[1]}"

		server_id=$(getFormattedString "$id" 4)
		user=$(getFormattedString "$user" 12)
		host=$(getFormattedString "$host" 31)
		echo "║ $id  ║$user║$host║"
		id=$(($id + 1))
	done < ~/.ssh/ssh-list

	echo "╚════╩════════════╩═══════════════════════════════╝"

	echo "Напишите 'ssh-list -c <id>' для подключения к серверу"

}

# Количиство параметров у скрипта
params_count=$#

# Если параметры есть, то смотрим какой это параметр
if [ $params_count -ge 1 ]
then
	case "$1" in
	# Вызываем функцию для вывода помощи
	-h|-help) help;;
	# Вызываем функцию для добавления нового сервера
	-a|-add) add $2 $3 $4;;
	# Вызываем функцию для удаления сервера
	-d|-delete) echo "Удалить сервер";;
	# Вызываем фунцкию для установки скрипта
	# -i|-install) echo "Установить скрипт" ;;
	*) echo "Неизвестный параметр '$1'";;
	esac
	exit 1
fi

show
