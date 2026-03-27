

DS端根据PlayerID获取他的好友列表；
当前PgosServerFriendAPI没有提供这个接口。
PgosClientFriendAPI提供接口，但是是在客户端用的，因为使用这个需要PGOS登陆。
当前有三种选择：
	- PGOS sdk升级，增加这个接口
	- 自己在DS端实现一套PGOS的http访问模块
	- DS和GS通信，使用GS端已有的PGOS的http访问模块
	
**等着岳明去和各方商量决定**

PGOS-http访问文档：
[Specification | PGOS](https://pgos.intlgame.com/pgosdoc/sdk_reference/http_api/Specification.html#1-overview)
[PGOS Backend HTTP API | PGOS](https://pgos.intlgame.com/pgosdoc/httpapi#tag/Player-Deletion/paths/~1player~1actual_delete_player/post)













## 废弃代码

以下是客户端用的代码，FriendManager类写在OnlineLibraries插件里。
已经被废弃。

```cpp
// BasePlayerState.cpp 中的示例
if (OnlineManagerModule && OnlineManagerModule->GetFriendsManager())
{
    return OnlineManagerModule->GetFriendsManager()->RequestAddFriend(PgogId);
}
```

现在用的是UFriendsManagerBase类及派生的UFriendsManagerPGOS类。





















