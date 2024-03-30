#!/bin/sh

ipv4_api_a="ipv4.icanhazip.com"
ipv6_api_a="api6.ipify.org"    
ip_file="ip.txt"               
id_file="cloudflare_ddns.ids"  
log_file="cloudflare_ddns.log" 

# 日志函数
log() {
    if [ "$1" ]; then
		local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
		echo -e "[$timestamp] - $1"
        #echo -e "[$timestamp] - $1" >> $log_file
    fi
}

sendmail(){	
	if [ -f "email.txt" ] && [ -s "email.txt" ]; then
		rm -f email.tmp && cp email.txt email.tmp
		sed -i "s/oldip/${1}/g" email.tmp
		sed -i "s/newip/${2}/g" email.mp
		ssmtp ${EMAIL} < email.tmp
	else 
		log "未找到邮件通知配置，不通知！"
    fi
}

if [ -z "$CF_EMAIL" ]; then
  log "请提供CloudFlare注册账户邮箱！"
  exit
fi
if [ -z "$CF_KEY" ]; then
  log "请提供CloudFlare账户的Globel ID！"
  exit
fi
if [ -z "$CF_ZONE_NAME" ]; then
  log "请提供主域名，例如example.com"
  exit
fi
if [ -z "$CF_RECORD_NAME" ]; then
  log "请提供需要的完整的DDNS解析域名，例如www.example.com"
  exit
fi
if [ -z "$CF_RECORD_TYPE" ]; then
  log "请提供解析类型：A对应ipv4，AAAA对应ipv6解析"
  exit
fi
if [ -z "$IPV4_API" ]; then
  log "ipv4测试地址：$ipv4_api_a"
else
  ipv4_api_a=$IPV4_API
  log "ipv4测试地址：$ipv4_api_a"
fi
if [ -z "$IPV6_API" ]; then
  log "ipv6测试地址：$ipv6_api_a"
else
  ipv6_api_a=$IPV6_API
  log "ipv6测试地址：$ipv6_api_a"
fi



#获取域名和授权
if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CF_ZONE_NAME" -H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $CF_KEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$CF_RECORD_NAME" -H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $CF_KEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
    echo "$zone_identifier" > $id_file
    if [ $zone_identifier == $(head -1 $id_file) ] && [ -n "$zone_identifier" ]; then
        log "获取zone_id成功!"
    else 
         log "获取zone_id失败!请检查网络和Globel ID是否正确并删除cloudflare_ddns.ids文件后从新运行."
         exit
    fi
    echo "$record_identifier" >> $id_file
    if [ $record_identifier == $(tail -1 $id_file) ] && [ -n "$record_identifier" ]; then
         log "获取record_id成功!"
         echo "0.0.0.0" > $ip_file
         log "第一次运行,创建ip.txt文件成功!"
    else 
         log "获取record_id失败!请检查网络和Globel ID是否正确并删除cloudflare_ddns.ids文件后从新运行."
         exit
    fi
    
fi
# 判断是A记录还是AAAA记录
if [ $CF_RECORD_TYPE = "A" ];then
    ip=$(curl -s $ipv4_api_a)
	log "网络获取IPV4成功!IP:$ip"
elif [ $CF_RECORD_TYPE = "AAAA" ];then
    ip=$(curl -s $ipv6_api_a)
	log "网络获取IPV6成功!IP:$ip"
else
    log "解析类型错误!"
    exit
fi

#判断ip是否发生变化
if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        log "IP没有更改!"
        log "----------------------------------------------------------------------"
        exit
    fi
fi
#更新DNS记录
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $CF_KEY" -H "Content-Type: application/json" --data "{\"type\":\"$CF_RECORD_TYPE\",\"name\":\"$CF_RECORD_NAME\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}")
#反馈更新情况
if [ "$update" != "${update%success*}" ] && [ "$(echo $update | grep "\"success\":true")" != "" ]; then
  log "IP更新成功！"
  log "上次IP:$(cat $ip_file),本次IP:$ip"
  sendmail $(cat $ip_file) $ip
  log "----------------------------------------------------------------------"
  echo $ip > $ip_file
  exit
else
  log "更新失败啦!"
  log "回复: $update"
  log "----------------------------------------------------------------------"
  exit
fi
