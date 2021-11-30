# Racket eval服务HTTP API文档
只有一个接口：`求值`。

### 求值
**描述**：对程序或表达式进行求值或执行。  
**path**：`/`  
**method**：`POST`
#### 参数
*JSON:*
```json
{
  expr: string, // 代码
  sender: { // 发送者，非必选参数
    id: number, // id
    nickname: string, // 昵称
    avatarUrl: string, // 头像url
  }
}
```

#### 响应
*JSON:*
```json
{
  output: string, // 输出，display、print等过程的输出，可能为空。
  value: string, // 表达式的值，如果没有错误，一定会有值（包括空字符串）
  error: string, // 错误信息，如果有值，output、value的值将是空。
}
```