# Funcraft + OSS + ROS 进行 CI/CD

## 前言

首先介绍下在本文出现的几个比较重要的概念：

> **函数计算（Function Compute）**：函数计算是一个事件驱动的服务，通过函数计算，用户无需管理服务器等运行情况，只需编写代码并上传。函数计算准备计算资源，并以弹性伸缩的方式运行用户代码，而用户只需根据实际代码运行所消耗的资源进行付费。函数计算更多信息[参考](https://help.aliyun.com/product/50980.html)。

> **Funcraft**：Funcraft 是一个用于支持 Serverless 应用部署的工具，能帮助您便捷地管理函数计算、API 网关、日志服务等资源。它通过一个资源配置文件（template.yml），协助您进行开发、构建、部署操作。Fun 的更多文档[参考](https://github.com/aliyun/fun)。

> **OSS**: 对象存储。海量、安全、低成本、高可靠的云存储服务，提供99.9999999999%的数据可靠性。使用RESTful API 可以在互联网任何位置存储和访问，容量和处理能力弹性扩展，多种存储类型供选择全面优化存储成本。

> **ROS**：资源编排（ROS）是一种简单易用的云计算资源管理和自动化运维服务。用户通过模板描述多个云计算资源的依赖关系、配置等，并自动完成所有资源的创建和配置，以达到自动化部署、运维等目的。编排模板同时也是一种标准化的资源和应用交付方式，并且可以随时编辑修改，使基础设施即代码（Infrastructure as Code）成为可能。

> **CI/CD**: CI/CD 是一种通过在应用开发阶段引入自动化来频繁向客户交付应用的方法。CI/CD 的核心概念是持续集成、持续交付和持续部署。

## 目标

本文打算以一个简单的函数计算项目为例，在此基础上编写测试用例，进行配置，让其支持 CI/CD 工作流程。实现如下四个小目标：

1. CI 被 git commit 提交触发
2. 执行测试（单元、集成和端对端）
3. 函数打包上传到 OSS
4. 通过 ROS 部署函数到 Staging 环境

## 工作流程图

![image.png](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/6beeb2a22af78cf7059a1158d40c7726.png)

这里以大家熟悉的 Github 仓库为例，并结合 Travis CI 。当用户往示例项目 push 或者 PR（Pull Request）时，会自动触发 Travis CI 的工作任务，进行单元测试、构建打包和部署发布。

## 示例项目

示例项目地址为：https://github.com/vangie/tz-time , 该项目是基于 FC Http trigger 实现的简单 web 函数，访问放函数是会返回指定时区的当前时间。项目目录结构如下

```text
tz-time
├── .funignore
├── .travis.yml
├── Makefile
├── bin
│   ├── delRosStack.sh
│   ├── deployE2EStack.sh
│   └── waitForServer.sh
├── deploy.log
├── index.e2e-test.js
├── index.integration-test.js
├── index.js
├── index.test.js
├── jest.config.e2e.js
├── jest.config.integration.js
├── package-lock.json
├── package.json
└── template.yml
```

部分文件作用介绍：

* `.funignore`  - Funcraft 部署时忽然的文件清单
* `.travis.yml` - Travis CI 配置文件
* `index.js` - 函数入口文件
* *.test.js - 单元测试相关文件
* *.integraion-test.js - 集成测试相关文件
* *.e23-test.js - 端对端测试相关文件
* template.yml - ROS 描述文件，用于描述函数和其他云服务

## 自动化测试

测试通常非常如下三类：单元测试、集成测试和 E2E 测试。在函数计算场景下，这三类测试可以通过如下方法实现。

* 单元测试 - 使用 Mock 类测试函数，验证输入输出参数
* 集成测试 - 使用 `fun local invoke/start` 模拟运行函数
* E2E 测试 - 使用 fun deploy 部署一套 test 环境，然后通过 fun invoke 进行模拟调用或者通过 curl 直接发送

本例子只实现了单元测试，集成测试和 E2E 测试对于 travis 示例来说触发方法类似，实现方法可以参见上面的方法提示进行配置。

### 单元测试

FC 函数的单元测试和普通的函数并无二致。采用熟悉的单元测试框架即可，本例中使用了 jest 进行测试。下面看看一个测试用例的代码片段

```javascript
jest.mock('moment-timezone');

const { tz } = require('moment-timezone');
const { handler } = require('./index');

const EXPECTED_DATE = '2018-10-01 00:00:00';
const TIMEZONE = 'America/New_York';

describe('when call handle', () => {
    it('Should return the expected date if the provied timezone exists', () => {
        const mockReq = {
            queries: {
                tz: TIMEZONE
            }
        }
        const mockResp = {
            setHeader: jest.fn(),
            send: jest.fn()
        }

        tz.names = () => [TIMEZONE];
        tz.mockImplementation(() => {
            return {
                format: () => EXPECTED_DATE 
            }
        })

        handler(mockReq, mockResp, null);

        expect(mockResp.setHeader.mock.calls.length).toBe(1);
        expect(mockResp.setHeader.mock.calls[0][0]).toBe('content-type');
        expect(mockResp.setHeader.mock.calls[0][1]).toBe('application/json');

        expect(mockResp.send.mock.calls.length).toBe(1);
        expect(mockResp.send.mock.calls[0][0]).toBe(JSON.stringify({
            statusCode: '200',
            message: `The time in ${TIMEZONE} is: ${EXPECTED_DATE}`
        }, null, '    '));

    });
});
```

通过 jest.mock 对 moment-timezone 进行 mock，让 tz 被调用的时候返回预先设定好的值，而不是一个动态变化的时间。

通常该类单元测试分为三步：

1. mock 依赖的值或者参数
2. 调用测试函数
3. 断言返回结果和被调用的参数

如果依赖包不存在原生依赖（依赖 linux 下的可执行文件或者 so 库文件）的使用 npm test 触发测试即可，如果有原生依赖，那测试需要跑在 fun 提供的 sbox 模拟环境里，使用如下命令触发

```bash
fun install sbox -f tz-time --cmd 'npm install'
```

### 集成测试

本例子中的集成测试会借助 fun local start 命令把函数在本地启动起来，由于函数配置了 http trigger，所以可以通过 http 请求调用函数。

集成测试我们还是才是 jest 框架进行编写，为了区别于单元测试文件 `*.test.js` ，集成测试文件使用 `.integration-test.js` 文件后缀。为了让 jest 命令独立的跑集成测试用例而不是和单元测试混和在一起，需要编撰如下文件 jest.config.integration.js 

```javascript
module.exports = {
    testMatch: ["**/?(*.)integration-test.js"]
};
```

然后在 package.json 中配置 scripts 

```javascript
"scripts": {
    "integration:test": "jest -c jest.config.integration.js"
}
```

于是可以通过执行 npm run integration:test 来执行集成测试。

然后在此基础上在 Makefile 中添加 integration-test 目标：

```Makefile
funlocal.PID:
	fun local start & echo $$! > $@

integration-test: funlocal.PID 
	bin/waitForServer.sh http://localhost:8000/2016-08-15/proxy/tz-time/tz-time/
	npm run integration:test
	kill -2 `cat $<` && rm $<
```

integration-test 目标依赖 funlocal.PID 目标，后者负责启动一个 fun local 进程，该进程会在本地启动 8000 端口。解读一下上面的 Makefile 代码

* `fun local start & echo $$! > $@` 启动 fun local 进程，并将进程 PID 写入到目标同名文件 funlocal.PID
* `bin/waitForServer.sh http://localhost:8000/2016-08-15/proxy/tz-time/tz-time/` 通过一个 url 测试 fun local 进程是否启动完成。
* ``kill -2 `cat $<` && rm $<`` 测试完成以后销毁 fun local 进程。

`npm run integration:test` 会启动若干的测试用例，其中一个测试用例如下:

```javascript
const request = require('request');

const url = 'http://localhost:8000/2016-08-15/proxy/tz-time/tz-time/';

describe('request url', () => {
    it('without tz', (done) => {
        request(url, (error, response, data) => {
            if (error) {
                fail(error);
            } else {
                const resData = JSON.parse(data);
                expect(resData.statusCode).toBe(200);
                expect(resData.message).toContain('Asia/Shanghai');
            }
            done();
        });
    });
});
```

### 端对端测试

端对端测试和集成测试的测试用例非常的类似，区别在于测试的服务端，端对端测试部署一套真实的环境，集成测试通过 fun local 本地模拟。

本例中借助 `fun deploy --use-ros` 部署一套环境，环境名称为 `tz-e2e-` 前缀带上时间戳，这样每次测试都会部署一套新的环境，不同环境之间相互不会影响。测试完成再通过 aliyun-cli 工具把 ROS 的 stack 删除即可。

下面端对端测试的 Makefile 目标：

```Makefile
stack_name := tz-e2e-$(shell date +%s)

e2e-test:
	# deploy e2e 
	bin/deployE2EStack.sh $(stack_name)
	# run test
	npm run e2e:test
	# cleanup
	bin/delRosStack.sh $(stack_name)
```

* `bin/deployE2EStack.sh $(stack_name)` 负责部署一个新的 ROS stack。部署之前需要使用 fun package 构建交付物，具体如何构建交付物可以参考下一小节。
* `npm run e2e:test` 运行端对端测试
* `bin/delRosStack.sh $(stack_name)` 测试完成之后，清理部署的 ROS stack，会释放掉响应的云资源。

## 构建交付物

`fun package` 命令可被用于构建交付物，`fun package` 需要指定一个 OSS 的 bucket。fun package 命令会完成如下步骤：

1. 将代码编译打包成 Zip 文件。
2. 上传代码包到 OSS bucket。
3. 生成新的文件 template.packaged.yml，其中代码本地地址改为 OSS bucket 地址。

生成的 template.packaged.yml 文件就是最终交付物，可以通过 fun deploy 命名进行部署。

## 持续部署

当构建环节生成了交付物以后，就可以通过 fun deploy 进行部署了。持续部署需要解决如下两个问题：

1. 支持全新部署和升级部署
2. 一套资源描述支持部署多套，比如 test 环境、staging 环境和 production 环境。

`fun deploy` 借助于 ROS，可以轻松的解决上述问题。

```bash
fun deploy --use-ros --stack-name tz-staging --assume-yes
```

其中：

* `--use-ros` 表示借助于 ROS 进行部署，其工作机制是将 template.yml 推送到 ROS 服务，由 ROS 服务执行每个服务的新建和更新操作。如果没有该参数，fun 就会在本地解析 template.yml，调用 API 进行资源创建。ROS 有个额外的好处是可以进行部署的回滚，失败的时候能自动进行回滚。
* `--stack-name` 指定一个 stack 的名称，stack 是 ROS 的概念，可以理解为一套环境。
* `--assume-yes` 用于无人值守模式，跳过确认提示。

## 小结

上面所有步骤的脚本化配置可以参考 Makefile 和 .travis.yml 文件。通过上述两个文件可以实现 Github 和 Travis CI 的联动，实现基于代码提交触发的 CI/CD。

本文讲述了 FC 函数

1. 如何进行测试，特别是单元测试的自动化
2. 如何构建交付物，通过 fun package 将代码文件上传到 OSS Bucket，让交付物编程一个文本描述文件 template.packaged.yml
3. 如何持续部署，借助于 ROS 部署多套环境，多次更新同一套环境。
