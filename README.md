# eval-server

执行Lisp程序的服务器。

### 准备
#### 0. 安装 [Racket](https://www.racket-lang.org/)
Windows 安装 DrRacket。  
Linux 安装 Racket。

#### 1. 配置
在`config.rkt`中修改变量：
- `admin-ids` 管理员id。  
- `server-port` 服务端口。

### 编写库
`user-lib`实现初始程序库。

### 运行
在DrRacket中运行 `main.rkt`。  
或命令行：`racket main.rkt`。

### 文档
[HTTP API文档](http-api-doc.md)