#!/bin/sh

if [ -z "$EMAIL" ]; then
  log "未提供邮箱信息，跳过邮件通知！"
  exit
fi
if [ -z "$AUTHCODE" ]; then
  log "未提供QQ邮箱授权码，跳过邮件通知！"
  exit
fi

	cat << EOF > /etc/ssmtp/ssmtp.conf
# 默认发件人
root=$EMAIL
#  SMTP 服务器
mailhub=smtp.qq.com:587
# 用户邮箱
AuthUser=$EMAIL
# 用户授权码
AuthPass=$AUTHCODE
# 启用 TLS 加密以保护数据安全
UseTLS=YES
# 是否使用 STARTTLS 加密连接到 SMTP 服务器
UseSTARTTLS=YES
# 发件人地址始终为root地址，设置为 YES
FromLineOverride=YES
EOF

	cat << EOF > /etc/ssmtp/revaliases
root:$EMAIL:smtp.qq.com:587
EOF

	cat << EOF > email.txt
To: $EMAIL
From: $EMAIL
Subject: IP变动通知

上次IP：oldip，本次IP：newip.
EOF