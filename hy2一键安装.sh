#!/bin/bash

# 关闭防火墙
sudo ufw disable
echo "防火墙已关闭"

# 安装服务端
bash <(curl -fsSL https://get.hy2.sh/)
echo "Hysteria 服务端已安装"

# 生成随机认证密码
rp=$(openssl rand -base64 12)
echo "生成随机认证密码: $rp"

# 请求用户输入域名
read -p "请输入您的域名: " domain

# 请求用户输入端口号
read -p "请输入您想使用的端口号: " port

# 生成自签证书
echo "正在生成自签证书..."
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=$domain" -days 36500
sudo chown hysteria /etc/hysteria/server.key
sudo chown hysteria /etc/hysteria/server.crt
echo "自签证书已生成"

# 修改配置文件
cat << EOF > /etc/hysteria/config.yaml
listen: :$port #监听端口

acme:
  domains:
    - $domain
  email: hy2@$domain

auth:
  type: password
  password: $rp

masquerade:
  type: proxy
  proxy:
    url: https://bing.com #伪装网址
    rewriteHost: true
EOF
echo "配置文件已更新"

# 启动服务端
sudo systemctl start hysteria-server.service
echo "Hysteria 服务端已启动"

# 查看服务端状态
sudo systemctl status hysteria-server.service

# 输出订阅链接
echo "订阅链接：hysteria2://$rp@$domain:$port?insecure=0#$domain"
