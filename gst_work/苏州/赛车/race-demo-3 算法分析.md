
老胡认为这个demo他比较满意， 所以我们按照这个demo做就好

---

## js code
|-- event-library.js   事件库 
|-- track-layout-data.js 赛道数据
|-- ui.js 界面
|-- renderer.js 渲染
|-- main.js 入口
|----------------------------------------------------
|-- mock-api.js  服务端模拟计算结果
|-- track.js 赛道（赛道分段）
|-- race-engine.js 模拟赛事



## 1 mock-api.js

服务端预先计算好 事件和得分

```js
function buildServerScript()
{
	// 1 先根据公式计算所有car的基础分
	var baseScore = SCORE_W[0] * attr.top + SCORE_W[1] * attr.cor
        + SCORE_W[2] * attr.acc + SCORE_W[3] * attr.sta
        + (rnd() - 0.5) * 4; // 小幅性能波动
          
    // 2 根据基础属性，随机几个会退赛的记下来，排除以后的计算      
    dnfSet[victimD] = true;
    // 记录到事件表里
    
    // 3 多车事件 1~2个
    /// 基础分数接近的车，会更大机会聚在一起，所以假设他们会碰撞，直接扣分
    team.forEach(function (id) { carsById[id].score += scoreLoss; });
    // 记录到事件表里
    
    // 4 单车事件 2~3个, 找到稳定性低的车，假设他们会碰撞，直接扣分
    var loss = -pickRange(rnd, [Math.abs(tplS.scoreMin), Math.abs(tplS.scoreMax)]);
    carsById[victim].score += loss;
    // 记录到事件表里
    
    // 5 安全车事件 0-1个， 不扣分
    // 记录到事件表里
    
    // 6 根据得分计算排名
    
    // 7 计算出发车顺序 WarmShuffle算法
}
```


## 2 track.js