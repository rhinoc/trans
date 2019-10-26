# trans
a small and fast translator living in macOS menu bar


前几天在macOS的App Store上看到一个叫「小翻译」的应用：

![](https://pic.rhinoc.top/mweb/15715563982330.jpg)

觉得挺简单的，监控剪贴板再随便调用一个在线翻译的API就行了。但是蓝色的图标放菜单太违和了。就想着自己能不能也做一个，于是「trans」就出来了。

和小翻译一样，trans也是一个菜单栏应用，目前支持输入搜索和复制搜索，搜索调用的接口是百度翻译的API。

点击菜单栏的图标可「输入搜索」：

![](https://pic.rhinoc.top/mweb/15717457312566.jpg)

![](https://pic.rhinoc.top/mweb/15717457549055.jpg)

保持后台开启，剪贴板变动的时候触发「复制搜索」，鼠标移到通知可复制翻译结果：

![](https://pic.rhinoc.top/mweb/15715578064917.jpg)

![](https://pic.rhinoc.top/mweb/15717457944937.jpg)


设想的应用场景和优势：
1. 浏览网页、文档时。由于是Application作为载体，所以相比于浏览器的划词翻译有更宽泛的使用场景。
2. 不需要精准翻译和单词管理时。相比欧路词典、有道词典更加轻量化，仅500KB，无论是磁盘还是内存占用都可忽略不计。
3. 希望获得更原生更自然的体验时。使用Swift语言开发的native应用，macOS原生控件。不需要的时候分分钟泯然众应用中。
4. 更安全，更隐私。由于能力不足没有历史记录等记录数据的功能，唯一的网络请求是GET百度翻译的API。
5. 调用百度翻译，相比内置词典有更全和更不准确的词库。

第一次接触macOS开发，由于是兴趣开发所以之后更不更新就随缘了，可能和~~稻米鼠停更他的公众号一样~~就再也不更新了。

梦想中的TO DO：
* [x] 复制翻译
* [x] 输入搜索翻译
* [ ] 设置-开机自启
* [x] 设置-原文语言和目标语言
* [ ] 设置-API选择和Token设置
* [ ] 第一次开启应用时不弹Popover
* [x] 输入翻译时的TextFiled显示优化
* [ ] 快捷键翻译

图标是在阿里爸爸的iconfont上找的，用Sketch做了个白色描边以适应暗黑模式。

源码放在[Github](https://github.com/rhinoc/trans)上，感兴趣的朋友可以自取，完全没有macOS基础开发的应用完全不遵守MVC也请多担待了。

想基于trans开发的小白朋友们可以参考：
* [Menus and Popovers in Menu Bar Apps for macOS](https://www.raywenderlich.com/450-menus-and-popovers-in-menu-bar-apps-for-macos)
* [macOS 开发之本地消息通知](https://www.smslit.top/2019/03/17/macOS-dev-local-notification/)
* [macOS应用开发基础之Popover](https://www.smslit.top/2018/06/29/macOS-dev-basic-NSPopover/)