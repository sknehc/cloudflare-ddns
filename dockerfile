# 使用 Alpine 作为基础镜像
FROM alpine:3.7

# 安装 所需软件
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.7/main/ > /etc/apk/repositories && apk update && apk add --no-cache curl grep tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 将 start.sh 脚本复制到镜像中
COPY start.sh /app/start.sh

# 设置脚本的执行权限
RUN chmod +x /app/start.sh

# 添加 crontab 文件
COPY crontab /etc/crontabs/root

# 定义工作目录
WORKDIR /app

# 启动 crond
CMD ["crond", "-f"]
