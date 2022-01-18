# Racket eval服务HTTP API文档
请求  
**method**：`POST`  
**body**：
```js
{
  path: string, // 接口名
  ... // 根据接口不同，有额外的字段，是下面各接口的“参数”。
}
```

### 求值
**描述**：对程序或表达式进行求值或执行。  
**path**：`eval`  
**参数**：(*JSON*)
```js
{
  env_id: string, // 环境名，global为全局
  expr: string,   // 代码
  sender: {       // 发送者，非必选参数
    id: number,        // id
    nickname: string,  // 昵称
    avatarUrl: string, // 头像url
  }
}
```

**响应**：(*JSON*)
```js
{
  code: number,   // 0为成功，非0为失败
  output: [       // 值和输出，可能为空。
    {type: 'text', content: string},
    {type: 'image', path, url},
    {type: 'audio', path, url},
    ...
  ],
  error: string,  // 错误信息
  data: {         // 如果结果失败，data是异常信息
    type: string, // 异常类型, 取值 'variable' | 'read' | 'syntax' | 'out-of-memory'，含义详见 racket的exn:fail文档
    id: string,   // 当 type = 'variable'时，表示未定义的变量名
  }
}
```