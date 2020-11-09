//
//  GameScene.swift
//  FlappyBird
//
//  Created by 田中美幸 on 2020/10/08.
//  Copyright © 2020 miyuki.tanaka2. All rights reserved.
//

import SpriteKit

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    //親ノードを宣言
    var scrollNode:SKNode!
    
    //ゲームオーバー時に止めないからscrollNodeと別で宣言
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    
    //カテゴリー(衝突判定に使うIDのこと)(カテゴリーを使ってどのスプライトが衝突したか判断する)
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    //スコアをカウントする
    var score = 0
    var itemScore = 0
    
    //スコアを表示させる
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    var bestItemScoreLavelNode: SKLabelNode!
    
    //UserDefaultsクラスのUserDefaults.standardプロパティで値を保存する仕組みを得る
    let userDefaults:UserDefaults = UserDefaults.standard
    
    let itemSound = SKAction.playSoundFileNamed("pa1.mp3", waitForCompletion: false)
    
    //SKView上にシーンが表示されたときに呼ばれるメソッド（viewDidLoad的な）
    override func didMove(to view: SKView) {
        
        //重力を設定(physicsWorldのgravityプロパティを使う)
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色(最大数は1)
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
    
        //ゲームオーバー時に一括で止めるために親ノードを作成
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノードを作成
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //アイテム用のノードを作成
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        //メソッドを分割してスッキリさせる
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()
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
            
            //物理演算を受けられるように四角形のスプライトとして設定
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //自身のカテゴリーを選択する
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突した時に動かないようにする
            sprite.physicsBody?.isDynamic = false
            
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
            
            //物理演算を受けられるように四角形のノードとして設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突したら動かないようにする
            under.physicsBody?.isDynamic = false
            
            //下の壁を追加する
            wall.addChild(under)
            
            //壁の画像を取得(テクスチャを作成)
            let upper = SKSpriteNode(texture: wallTexture)
            
            //壁の上部の位置を指定する
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //物理演算を受けられるように四角形のノードとして設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突したら動かないようにする
            upper.physicsBody?.isDynamic = false
            
            //上の壁を追加する
            wall.addChild(upper)
            
            //見えないけど衝突した時にカウントするノードを追加する
            let scoreNode = SKNode()
            
            //見えないけど衝突した時にカウントするノードの位置を設定する
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            
            //物理演算を受けられるように四角形のノードとして設定
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            
            //衝突したら動かないようにする
            scoreNode.physicsBody?.isDynamic = false
            
            //自身のカテゴリーを選択する
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            
            //衝突の判定対象を指定する
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            //見えないけど衝突した時にカウントするノードを追加する
            wall.addChild(scoreNode)
            
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
    
    func setupBird() {
        
        //鳥の画像を読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成(リピートさせる)
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        
        //鳥を表示する位置を指定する
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //鳥が重力を受けて下に落ちていく
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //どのカテゴリーを使うのか設定する
        bird.physicsBody?.categoryBitMask = birdCategory
        
        //自身のカテゴリーを指定する
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        
        //衝突の判定対象を指定する
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        //アニメーションをbirdに設定する
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
    
    func setupItem() {
        
        //アイテムの画像を読み込む(テクスチャを作成)
        let itemTexture = SKTexture(imageNamed: "item")
        
        let wallTexture = SKTexture(imageNamed: "wall")
        
        //当たり判定する画像はlinearにして画像を優先させる
        itemTexture.filteringMode = .linear
        
        //移動距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //4秒間でmovingDistanceの距離を移動するアクション
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        //自身を取り除くアクション
        let removeItem = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクション(スクロールした後、自身を取り除く)
        let ItemAnimation = SKAction.sequence([moveItem, removeItem])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        //let slit_length = itemTexture.size
        
        //隙間位置をランダムに上下させる際の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        
        //下のアイテムの最も低い位置を計算 ↓↓↓
        //groundのサイズを取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        
        //アイテムが見える所の中心
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        //下のアイテムの最も低い位置
        let item_lowest_y = center_y - itemTexture.size().height - random_y_range / 2
        
        //アイテムを生成するアクション
        let createItemAnimation = SKAction.run({
            
            //アイテムの情報を乗せるノードを作成
            let item = SKSpriteNode(texture: itemTexture)
            
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            //アイテムを表示する位置を指定
            item.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: item_lowest_y + random_y)
            
            //雲より手前、地面より奥に表示する
            item.zPosition = -50
            
            //0〜random_y_rangeまでのランダム値を生成
            
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            //let under_item_y = item_lowest_y + random_y
            
            //アイテムの画像を取得(テクスチャを作成)
            //let under = SKSpriteNode(texture: itemTexture)
            
            //下側のアイテムの位置を指定
            //under.position = CGPoint(x: 0, y: under_item_y)
            
            //物理演算を受けられるように四角形のノードとして設定
            item.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            
            //衝突したら動かないようにする
            //under.physicsBody?.isDynamic = false
            
            //下のアイテムを追加する
            //item.addChild(under)
            
            //アイテムの画像を取得(テクスチャを作成)
            //let upper = SKSpriteNode(texture: itemTexture)
            
            //アイテムの上部の位置を指定する
            //upper.position = CGPoint(x: 0, y: under_item_y + itemTexture.size().height)
            
            //物理演算を受けられるように四角形のノードとして設定
            //upper.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            
            //衝突したら動かないようにする
            //upper.physicsBody?.isDynamic = false
            
            //上のアイテムを追加する
            //item.addChild(upper)
            
            //見えないけど衝突した時にカウントするノードの位置を設定する
            //item.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            
            //物理演算を受けられるように四角形のノードとして設定
            //item.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            
            //衝突したら動かないようにする
            item.physicsBody?.isDynamic = false
            
            //自身のカテゴリーを選択する
            item.physicsBody?.categoryBitMask = self.itemCategory
            
            //衝突の判定対象を指定する
            item.physicsBody?.contactTestBitMask = self.birdCategory
            
            //アイテムにItemAnimation機能を設定する
            item.run(ItemAnimation)
            
            //itemNodeにitemを追加する
            self.itemNode.addChild(item)
        })
        
        //次の壁作成までの時間待ちのアクション(壁が作成できても2秒間まつ)
        let waitAnimation = SKAction.wait(forDuration: 1)
        let waitAnimation2 = SKAction.wait(forDuration: 1)
        
        //壁を作成->時間待ち->壁を作成を無限に繰り返すアクション
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation2, createItemAnimation, waitAnimation]))
        
        //itemNodeにrepeatForeverAnimationの機能を設定する
        itemNode.run(repeatForeverAnimation)
    }
    
    func setupScoreLabel() {
        
        //初めのスコアは0
        score = 0
        
        //プロパティを指定
        scoreLabelNode = SKLabelNode()
        
        //ラベルの色を指定
        scoreLabelNode.fontColor = UIColor.black
        
        //ラベルの位置を指定
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        
        //ラベルを一番上に持ってくるように設定
        scoreLabelNode.zPosition = 100
        
        //左詰めに表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        //ラベルに反映
        scoreLabelNode.text = "Score:\(score)"
        
        //scoreLabelNodeを追加する
        self.addChild(scoreLabelNode)
        
        //プロパティを指定
        bestScoreLabelNode = SKLabelNode()
        
        //ラベルの色を指定
        bestScoreLabelNode.fontColor = UIColor.black
        
        //ラベルの位置を指定
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        
        //ラベルを一番上に持ってくるように設定
        bestScoreLabelNode.zPosition = 100
        
        //左詰めに表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        //ベストスコアをのデータを取得する
        let bestScore = userDefaults.integer(forKey: "BEST")
        
        //ラベルに反映
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        
        //ベストスコアを追加する
        self.addChild(bestScoreLabelNode)
        
        //アイテムスコアラベル
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        //アイテムベストスコアラベル
        bestItemScoreLavelNode = SKLabelNode()
        bestItemScoreLavelNode.fontColor = UIColor.black
        bestItemScoreLavelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
        bestItemScoreLavelNode.zPosition = 100
        bestItemScoreLavelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestItemScore = userDefaults.integer(forKey: "BESTITEM")
        bestItemScoreLavelNode.text = "Item Best Score:\(bestItemScore)"
        self.addChild(bestItemScoreLavelNode)
    }
    
    //衝突した時に呼ばれるメソッド
    func didBegin(_ contact: SKPhysicsContact) {
        
        //スクロールが停止になりゲームオーバーになった時
        if scrollNode.speed <= 0 {
            
            //何もしない(壁に衝突してゲームオーバーになった後、地面にも衝突するので2度目の処理を行うことになるのを防ぐ)
            return
        }
        
        //引数の持つSKPhysicsBodyプロパティ(bodyA・bodyB)を使って何と何が衝突したか判定する
        //スコア用の物体と衝突した時
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            //BESTをキーにして指定する・bestScoreを宣言する
            var bestScore = userDefaults.integer(forKey: "BEST")
            
            //もしスコアがベストスコアより高かった時
            if score > bestScore {
                
                //今回のスコアをベストスコアにする
                bestScore = score
                
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                
                //キーを指定して保存する
                userDefaults.set(bestScore, forKey: "BEST")
                
                //即座に保存させる
                userDefaults.synchronize()
                
            }
            //アイテム用の物体とぶつかった時
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            
            print("PointUp")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            var bestItemScore = userDefaults.integer(forKey: "BESTITEM")
            
            self.run(itemSound)
            
            //もしスコアがベストスコアより高かった時
            if itemScore > bestItemScore {
                
                //今回のスコアをベストスコアにする
                bestItemScore = itemScore
                
                bestItemScoreLavelNode.text = "Item Best Score:\(bestItemScore)"
                
                //キーを指定して保存する
                userDefaults.set(bestItemScore, forKey: "BESTITEM")
                
                //即座に保存させる
                userDefaults.synchronize()
            }
            
            //ぶつかったアイテムを消す
            if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory{
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            //壁か地面に衝突した時
        } else {
            
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            //衝突の判定対象を地面だけにする（地面と衝突した時のみアクションを設定したい・そのまま落下させたい）
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //回転するアクションを定義
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            
            //回転が終わって地面に衝突したら
            bird.run(roll, completion:{
                
                //スクロールを停止させる
                self.bird.speed = 0
            })
        }
        
    }
    
    func restart() {
        
        //スコアをゼロに戻す
        score = 0
        itemScore = 0
        
        //鳥の位置を初期位置に戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //速度をゼロに戻す
        bird.physicsBody?.velocity = CGVector.zero
        
        //衝突の判定対象を設定する(地面と壁)
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        
        //回転をなくす
        bird.zRotation = 0
        
        //取り除く
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        //鳥とスクロールの速度を戻す
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    //画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //スクロールのスピードが0以上(鳥が停止していない)時は
        if scrollNode.speed > 0 {
            
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
            //鳥が停止している時は
        } else if bird.speed == 0 {
            
            //ゲームを再開する
            restart()
        }
    }
}
