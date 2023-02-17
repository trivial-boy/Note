## SpringSecurity 原理

### SpringSecurity 完整流程

springsecurity 的原理其实是一个过滤器链，内部包含了提供各种功能的过滤器。

![image-20220602161622174](http://img.trivial.top/img/image-20220602161622174.png)

图中只展示了核心过滤器，其他的非核心未展示

UsernamePasswordAuthicationFilter 负责处理我们在登录页面填写了用户名密码后的登录流程。

ExceptionTranslationFilter ：处理过滤器链中抛出的 AccessDeniedException 和 AuthenticationException

FilterSecurityInterceptor: 负责校验的过滤器

**debug技巧**

![image-20220602162718200](http://img.trivial.top/img/image-20220602162718200.png)

点击这里可以输入代码执行

<img src="http://img.trivial.top/img/image-20220602162742611.png" alt="image-20220602162742611" style="zoom:50%;" />

输入run.getBean(DefaultSecurityFilterChain.class)

<img src="http://img.trivial.top/img/image-20220602162822297.png" alt="image-20220602162822297" style="zoom:50%;" />

### 认证流程

![image-20220602163203704](http://img.trivial.top/img/image-20220602163203704.png)

![image-20220602165407682](http://img.trivial.top/img/image-20220602165407682.png)