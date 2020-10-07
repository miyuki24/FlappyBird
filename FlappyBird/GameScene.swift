//
//  GameScene.swift
//  FlappyBird
//
//  Created by 田中美幸 on 2020/10/07.
//  Copyright © 2020 miyuki.tanaka2. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    //親ノードを宣言
    var scrollNode:SKNode!
    
    //ゲームオーバー時に止めないからscrollNodeと別で宣言
    var wallNode:SKNode!
    
    //SKView上にシーンが表示されたときに呼ばれるメソッド（viewDidLoad的な）
    override func didMove(to view: SKView) {
        
        //背景色(最大数は1)
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //ゲームオーバー時に一括で止めるために親ノードを作成
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノードを作成
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //メソッドを分割してスッキリさせる
        setupGround()
        setupCloud()
        setupWall()
    }
    
    func setupGround() {
        
        //地面の画像を読み込む（処理優先）
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算(右端が切れないように＋2する)
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //SKActionを生成 ↓↓↓
        //左方向に5秒かけてスクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置
        for i in 0..<needNumber {
            
            //スプライト作成
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //SKActionを生成 ↓↓↓
        //左方向に5秒間でスクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            
            //スプライト作成
            let sprite = SKSpriteNode(texture: cloudTexture)
            
            //2Dゲームだけど奥行き（z）をつける。一番後ろになるように表示。
            sprite.zPosition = -100
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        
        //壁の画像を読み込む(テクスチャを作成)
        let wallTexture = SKTexture(imageNamed: "wall")
        
        //当たり判定する画像はlinearにして画像を優先させる
        wallTexture.filteringMode = .linear
        
        //移動距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //4秒間でmovingDistanceの距離を移動するアクション
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        //自身を取り除くアクション
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクション(スクロールした後、自身を取り除く)
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        
        //隙間位置をランダムに上下させる際の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        
        //下の壁の最も低い位置を計算 ↓↓↓
        //groundのサイズを取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        
        //壁が見える所の中心
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        //下の壁の最も低い位置
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクション
        let createWallAnimation = SKAction.run({
            
            //壁の情報を乗せるノードを作成
            let wall = SKNode()
            
            //壁を表示する位置を指定
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            
            //雲より手前、地面より奥に表示する
            wall.zPosition = -50
            
            //0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //壁の画像を取得(テクスチャを作成)
            let under = SKSpriteNode(texture: wallTexture)
            
            //下側の壁の位置を指定
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //下の壁を追加する
            wall.addChild(under)
            
            //壁の画像を取得(テクスチャを作成)
            let upper = SKSpriteNode(texture: wallTexture)
            
            //
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //上の壁を追加する
            wall.addChild(upper)
            
            //壁にwallAnimation機能を設定する
            wall.run(wallAnimation)
            
            //wallNodeにwallを追加する
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの時間待ちのアクション(壁が作成できても2秒間まつ)
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成->時間待ち->壁を作成を無限に繰り返すアクション
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        //wallNodeにrepeatForeverAnimationの機能を設定する
        wallNode.run(repeatForeverAnimation)
    }
}
