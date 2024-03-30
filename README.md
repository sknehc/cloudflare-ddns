```
docker run -d --name cloudflare-ddns \
	-e CF_EMAIL=test@qq.com \
	-e CF_KEY=xxxx \
	-e CF_ZONE_NAME=test.com \
	-e CF_RECORD_NAME=www.test.com  \
	-e CF_RECORD_TYPE=A \
        -e EMAIL=TEST@qq.com
        -e AUTHCODE=yyyy
	sknehc/cloudflare-ddns
```
在使用该镜像前，请先在cloudflare的dns解析中添加一条记录。该镜像默认间隔10分钟检查一次ip。

CF_EMAIL：cloudflare的注册邮箱

CF_KEY：cloudflare账户的Globel ID，详情

CF_ZONE_NAME：主域名

CF_RECORD_NAME：需要解析的全域名

CF_RECORD_TYPE：解析类型，A是ipv4，AAAA是ipv6

EMAIL：接收变更通知的qq邮箱 （变更通知可选）

AUTHCODE：接收变更通知的qq邮箱的授权码（变更通知可选）
