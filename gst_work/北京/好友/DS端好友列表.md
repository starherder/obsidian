

# 我在客户端控制台输入了 gm getfriendslist 1234 为何客户端显示Command not recognized: gm getfriendslist 12345

这是一个**非常典型、而且你现在正好踩到 UE Exec / CheatManager 注册链的“断点”**​ 👍

我直接给你**最可能的原因（按命中率）+ 对应解法**，一步步对。

---

## 一、先给你最关键的结论

> ✅ **`Command not recognized: gm getfriendslist`
> 
> 说明：
> 
> 👉 UE 找到了 `gm`前缀
> 
> 👉 但 **在 CheatManager 中没找到 `getfriendslist`这个 Exec 函数**

**不是函数名大小写问题，也不是 DS / 客户端问题。**

---

## 二、最常见原因（90% 都在这里）

---

### ✅ 原因 1（⭐ 最高概率）：CheatManager 根本没注册到 GameMode

你写了：

```
UCLASS()
class UGOLCheatManager : public UCheatManager
{
    GENERATED_BODY()

    UFUNCTION(Exec)
    void GM_GetFriendsList(const FString& PlayerID);
};
```

❌ 但 **GameMode 还在用默认的 CheatManager**

#### ✅ 必须做这一步（非常关键）

```
class AMyGameMode : public AGameModeBase
{
    virtual void InitGame(...) override
    {
        Super::InitGame(...);
        CheatClass = UGOLCheatManager::StaticClass();
    }
};
```

或者 **DefaultEngine.ini**：

```
[/Script/Engine.GameModeBase]
CheatClass=/Script/GOL.UGOLCheatManager
```

✅ 否则 UE 用的是 `UCheatManager`，里面当然没有你的函数。

---

### ✅ 原因 2：函数签名不合法（Exec 不支持）

```
void GM_GetFriendsList(const FString& PlayerID);
```

⚠️ **Exec 对参数非常挑剔**

#### ✅ 100% 安全的写法（推荐）

```
UFUNCTION(Exec)
void GM_GetFriendsList(FString PlayerID);
```

或：

```
UFUNCTION(Exec)
void GM_GetFriendsList(const FString PlayerID);
```

❌ 以下会直接失败（常见）：

```
const FString&
```

---

### ✅ 原因 3：PlayerController 还没生成

- 刚进游戏
    
- 还没登录
    
- 控制台输入太早
    

✅ 验证：

```
GetFirstLocalPlayerController(GetWorld())
```

---

### ✅ 原因 4：Shipping 版本被裁剪

UE 默认：

```
AllowCheats=false
```

✅ 解决：

```
[ConsoleVariables]
AllowCheats=true
```

---

## 三、如何 100% 确认“命令是否注册成功”

### ✅ 控制台输入

```
help gm
```

你应该能看到：

```
getfriendslist
```

如果看不到 → **一定没注册**

---

### ✅ C++ 调试（最准）

```
GEngine->Exec(GetWorld(), TEXT("gm getfriendslist 1234"));
```

如果还是 `not recognized`→ **CheatManager 没挂上**

---

## 四、为什么“GM_GetFriendsList”能直接执行？

因为你输入的是：

```
GM_GetFriendsList
```

UE 解析为：

```
exec function name = "gm_getfriendslist"
```

然后：

✅ 在 **本地 Exec 表**​ 中找到了

❌ 没走 `gm`→ CheatManager RPC

✅ 所以直接执行了

👉 **这和“命令没注册”是两回事**

---

## 五、一句话终极定位（你现在这个问题）

> **`Command not recognized: gm getfriendslist`
> 
> = CheatManager 没注册 / 函数签名不合法 / 参数写法错误**​
> 
> ✅ **和 DS / 客户端执行无关**

---

## 六、建议你现在立刻做这三步（按顺序）

1️⃣ 确认 GameMode 设置了 `CheatClass`

2️⃣ 把函数参数改成 `FString`（不要 `const&`）

3️⃣ 输入 `help gm`看有没有 `getfriendslist`

---

如果你愿意，下一步我可以帮你：

- ✅ **逐行检查你现在的 CheatManager / GameMode**
    
- ✅ **告诉你 Exec 参数支持/不支持的完整列表**
    
- ✅ **讲为什么 `const FString&`经常失败**
    
- ✅ **帮你设计一个“100% 可用的 DS GM 命令”**
    

你现在 **GameMode 里已经设置了 CheatClass 了吗？**

















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


---













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





















