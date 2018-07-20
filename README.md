## frost2D - Lightweight HTML5 game engine for Haxe

Ease of use, minimal infrastructure, and efficiency are the core principles of frost2D. It's goal is to keep you making web games, not wasting time dealing with cumbersome API's and such.

*Note: It's early in development, but stable versions are coming!*

### Documentation
Full source code documentation is available: [http://frost2d.com/docs/0.1.0/](http://frost2d.com/docs/0.1.0/)

### Example Code

```haxe
import frost2d.Game;
import frost2d.graphics.Sprite;

class HelloWorld extends Sprite {
    
    public static var root(default, never):HelloWorld = new HelloWorld();
    
    static function main() {
        Game.start(root, 800, 450, "#202020");
        Game.loader.onComplete = root.loaded;
    }
    
    private function loaded():Void {
        var ball:Sprite = new Sprite();
        ball.paint.beginFill("#ef0020");
        ball.paint.drawCircle(0, 0, 20);
        ball.x = Game.width / 2;
        ball.y = Game.height / 2;
        addChild(ball);
    }
    
}
```
