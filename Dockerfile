FROM golang:1.20.3 AS gobuild
WORKDIR /go/src/GoViewFile
RUN mkdir -p output
ENV GOPROXY="https://goproxy.cn|https://proxy.golang.org|direct"
ENV GO111MODULE="on"

COPY . .
RUN go build -v -o output/main .
RUN ls -lF output/

FROM centos:7.2.1511
# 设置固定的项目路径
WORKDIR /var/www/GoViewFile

# 添加应用可执行文件，并设置执行权限
# ADD main   $WORKDIR/main
COPY --from=gobuild /go/src/GoViewFile/output/main .
RUN chmod +x main

# MAINTAINER czc "file-preview"
COPY fonts/* /usr/share/fonts/ChineseFonts/


ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Shanghai

RUN  yum install java -y

RUN  yum  install deltarpm  -y  &&\          
     yum install  libreoffice -y &&\
     yum install libreoffice-headless -y &&\
     yum install libreoffice-writer -y &&\
     yum install ImageMagick -y  &&\
     export DISPLAY=:0.0     


# 添加I18N多语言文件、静态文件、配置文件、模板文件
ADD public   public
ADD config   config
ADD template template

# 添加本地上传文件目录
COPY cache/convert/  cache/convert/
COPY cache/download/  cache/download/
COPY cache/local/  cache/local/
COPY cache/pdf/  cache/pdf/
# jar包，用于将.msg文件转eml文件
COPY library/emailconverter-2.5.3-all.jar   /usr/local/emailconverter-2.5.3-all.jar

#pdf 添加水印
COPY library/pdfcpu    /usr/local/pdfcpu
RUN chmod +x /usr/local/pdfcpu

# 安装wkhtmltopdf 用于将eml（html）文件转pdf
RUN yum -y install wget openssl xorg-x11-fonts-75dpi
COPY rpm_packages/wkhtmltox-0.12.5-1.centos7.x86_64.rpm .
# RUN wget http://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox-0.12.5-1.centos7.x86_64.rpm  
RUN rpm -ivh wkhtmltox-0.12.5-1.centos7.x86_64.rpm


###############################################################################
#                                   START
###############################################################################
# 如果需要进入容器调式，可以注释掉下面的CMD. 
CMD  ./main  


# ------------------------------------本地打包镜像---------------------
# docker build -t  goviewfile:v0.7  .
# docker run -d  -p 8082:8082 镜像ID
