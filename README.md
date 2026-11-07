# 一、归档说明

这个仓库是微信小程序服务端 Ruby SDK 的历史快照，版本停在 0.1.1，不再继续开发。

文档说明源码里能直接看到的结构、配置、请求和返回处理。微信接口今天是否仍然可用，需要另向微信文档确认。

# 二、这个库做什么

wmp_sdk 把少量微信小程序后台接口包成 Ruby 类方法，给服务端调用。范围包括登录凭证校验、获取 access_token、统一服务消息、订阅消息、临时图片上传、客服消息，以及消息推送签名校验。

使用时先往全局配置写入小程序参数，再调用 WmpSdk::Api。令牌由调用方自己保存，再传给后续方法。库内没有令牌缓存、重试、日志和命令行入口。

# 三、源码怎么组织

1. lib/wmp_sdk.rb 定义模块入口。WmpSdk.configuration 在首次使用时创建一个配置对象，WmpSdk.configure 把这个对象交给代码块修改。
2. lib/wmp_sdk/configuration.rb 只有五个可读写字段：app_id、secret、miniprogram_state、token、encoding_aes_key。没有默认值。
3. lib/wmp_sdk/api.rb 实现全部请求和签名校验，方法都是类方法。
4. lib/wmp_sdk/error.rb 定义 WmpServerError，它继承 StandardError。
5. lib/wmp_sdk/version.rb 将版本定为 0.1.1。
6. spec/wmp_sdk_spec.rb 是 RSpec 示例。bin/setup 执行 bundle install，bin/console 进入 IRB。Rakefile 的默认任务是 spec。

# 四、配置怎么参与调用

配置保存在进程内的同一对象上。再次调用 WmpSdk.configure 会修改这份配置，库没有按请求隔离，也没有加锁。

1. app_id 和 secret 进入登录校验、获取 access_token 两个请求。
2. token 只参与消息推送签名校验。校验时如果 token 仍是 nil，Ruby 在排序字符串和 nil 时会抛出比较异常。
3. miniprogram_state 可以写入配置，源码中的业务方法没有读取它。订阅消息使用方法参数，默认值是 formal。
4. encoding_aes_key 可以写入配置，源码中没有任何读取。签名校验不做消息解密。

# 五、接口逻辑

HTTP 状态属于成功时，方法用 JSON.parse 把响应体解析成符号键哈希并原样返回。微信用 errcode 表示的业务错误，只要 HTTP 仍是成功状态，也会作为哈希返回，不会转成异常。响应体不是 JSON 时，解析异常会直接向外抛出。

1. invoke_auth_session(code) 做登录凭证校验。code 对应小程序 wx.login 得到的临时凭证。
- 请求是 GET https://api.weixin.qq.com/sns/jscode2session。
- 查询参数为 appid、secret、js_code、grant_type。grant_type 在源码里是符号 authorization_code。
- HTTP 状态不成功时抛出 WmpServerError，消息中包含状态码。
2. invoke_access_token 获取全局后台接口调用凭据。
- 请求是 GET https://api.weixin.qq.com/cgi-bin/token。
- 查询参数为 grant_type、appid、secret。grant_type 在源码里是符号 client_credential。
- 返回值保持微信原始字段。方法不提取 access_token 字符串，也不记录过期时间。
3. invoke_uniform_message(access_token, openid, mp_template_msg, weapp_template_msg = nil) 调用统一服务消息接口。
- 地址是 https://api.weixin.qq.com/cgi-bin/message/wxopen/template/uniform_send。
- JSON 正文包含 touser 和 mp_template_msg。第四个参数有值时，再放入 weapp_template_msg。
- 两个模板参数按调用方传入的对象序列化，方法内部不检查字段形状。
4. invoke_subscribe_message_send(access_token, openid, template_id, page, data, miniprogram_state = "formal", lang = "zh_CN") 发送订阅消息。
- 地址是 https://api.weixin.qq.com/cgi-bin/message/subscribe/send。
- JSON 正文包含 touser、template_id、page、data、miniprogram_state、lang。
- 环境默认 formal，语言默认 zh_CN。这两个值来自方法参数。
5. invoke_upload_temp_media(access_token, file_name) 把图片上传为临时素材。
- 地址是 https://api.weixin.qq.com/cgi-bin/media/upload，查询字符串包含 access_token 和 type=image。
- 文件路径取 Rails.root.join(file_name)，因此这段代码要求当前进程里存在 Rails。
- 上传类型固定为 image，文件的 Content-Type 固定写成 image/jpg。请求使用 multipart。
6. send_customer_service_message(access_token, openid, message_type, options = {}) 发送客服消息。
- 地址是 https://api.weixin.qq.com/cgi-bin/message/custom/send。
- 正文先写 touser 和 msgtype，再与 options 合并。文本、图片等消息体由调用方放进 options。
- options 里如果带有 touser 或 msgtype，会覆盖前面写入的同名字段。
7. validate_customer_service_message(signature, timestamp, nonce) 校验消息推送签名。
- 计算方式是把 token、timestamp、nonce 排序后直接拼接，再取 SHA1 的十六进制摘要，与 signature 做相等比较。
- 相等返回 true，不相等返回 false。方法不读取消息体，不处理 echostr，也不使用 encoding_aes_key。
- 源码没有 require "digest"。Digest 尚未加载时，这里会在常量查找阶段失败。

上面第 3、4、6 个方法都把 access_token 传给 Faraday.post 的第二个参数，并在代码块里改写 request.body。这个传递结果见第八节。

# 六、按源码整理的调用写法

下面是从入口整理出来的阅读示例，用来对照源码。这里没有实际执行。

```ruby
WmpSdk.configure do |config|
  config.app_id = "小程序 AppId"
  config.secret = "小程序 AppSecret"
  config.token  = "消息校验 Token"
end

session = WmpSdk::Api.invoke_auth_session("wx.login 返回的 code")
token_result = WmpSdk::Api.invoke_access_token
```

调用方从 token_result 中取出令牌后，自己传给订阅消息、客服消息或上传方法。配置里的 secret 和 token 属于小程序密钥，不应写进仓库。

# 七、依赖、测试和流水线

1. 运行接口需要 Faraday。Gemfile 约束 faraday 1.0.1 及以上的 1.x，并锁定 1.0.1。gemspec 没有把 faraday 写成运行时依赖，只执行 gem install 时不会带上它。
2. Faraday 1.0.1 会带上 multipart-post。上传方法使用 Faraday 的 multipart 和 FilePart。开发依赖是 rake 12.x 和 rspec 3.x，Bundler 版本锁定为 2.1.4。
3. spec 里有三个示例：版本号、配置赋值、调用 invoke_access_token。前两个写成 expect(...).eql? ...，没有使用 RSpec 的 to 匹配器，比较结果为假时示例也不会失败。
4. 获取令牌的示例会向微信真实地址发请求，只断言结果不是 nil。该示例自身没有写入 app_id 和 secret。按文件定义顺序整文件运行时，前一个示例会先改掉全局配置；单独运行这个示例时，配置仍是空的。
5. spec/wmp_sdk_spec.rb 里写有一组 AppId、密钥、Token 和 EncodingAESKey 样例值。归档阅读时只把它们当作测试残留，不要拿去调用微信。
6. .travis.yml 指定 Ruby 2.5.8，并在安装前安装 bundler 2.1.4。文件里没有 script。
7. .github/workflows/ruby.yml 的工作流名叫 Open The Faucet。触发方式只有定时任务，每 10 分钟一次，没有 push 或 pull_request。矩阵是 Ruby 2.6、2.7、3.0，步骤是安装依赖后执行 bundle exec rake。

# 八、静态阅读看到的问题

1. 统一服务消息、订阅消息、客服消息这三处，access_token 没有出现在 URL 查询字符串里。Faraday 1.x 里 post 的第二个参数是请求体，代码块随后又把 request.body 换成 JSON，原先的哈希会被替换掉。

```ruby
Faraday.post(url, { access_token: access_token }) do |request|
  request.body = request_body.to_json
end
```

2. 这三处设置了 JSON 字符串正文，没有同时设置 Content-Type。上传接口则把 access_token 和 type=image 直接写在 URL 上。
3. Faraday 连接没有配置超时、代理或重试。只有 HTTP 状态不成功才抛 WmpServerError。
4. 临时素材上传依赖 Rails.root，gem 本身没有声明 Rails。路径、素材类型和 image/jpg 都是按这一处实现固定的。
5. 配置项 miniprogram_state、encoding_aes_key 没有被读取。消息安全模式所需的解密不在这个库里。
6. 签名方法使用 Digest::SHA1，api.rb 没有加载 digest。
7. gemspec 把可执行文件目录写成 exe，仓库里实际是 bin，其中没有作为 gem 命令安装的可执行文件。打包文件列表依赖 git ls-files。
8. 持续集成文件里的工作流名称、每 10 分钟的定时触发，以及和 .ruby-version、gemspec 不一致的 Ruby 版本，都按文件原样保留。它们反映的是归档时的仓库状态。

# 九、许可

gem 以 MIT 协议开源，版权声明年份是 2020，权利人是 JiangYongKang。完整文本在 LICENSE.txt。

仓库另有一份 Contributor Covenant 1.4 行为准则，文件是 CODE_OF_CONDUCT.md。归档后的阅读和引用仍受上述许可约束。
