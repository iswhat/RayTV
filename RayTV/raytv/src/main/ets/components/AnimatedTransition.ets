import { AnimationManager } from '../managers/AnimationManager';
import { TransitionEffect } from '../types/AnimationTypes';

/**
 * 动画过渡容器组件
 * 提供丰富的页面切换和元素动画效果
 */
@Entry
@Component
struct AnimatedTransition {
  @State private isVisible: boolean = false;
  @State private animationProgress: number = 0;
  @State private currentEffect: TransitionEffect = TransitionEffect.FADE;
  
  private animationManager: AnimationManager = AnimationManager.getInstance();
  private animationController: Animator | null = null;

  // 组件属性
  @Prop show: boolean = false;
  @Prop effect: TransitionEffect = TransitionEffect.FADE;
  @Prop duration: number = 300;
  @Prop delay: number = 0;
  @Prop easing: Curve = Curve.EaseInOut;
  @Prop children: CustomComponent[] = [];
  @Prop onEnter?: () => void;
  @Prop onExit?: () => void;
  @Prop onTransitionEnd?: () => void;

  aboutToAppear(): void {
    this.currentEffect = this.effect;
    if (this.show) {
      this.animateIn();
    }
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  @Watch('show')
  onShowChange(newValue: boolean): void {
    if (newValue) {
      this.animateIn();
    } else {
      this.animateOut();
    }
  }

  @Watch('effect')
  onEffectChange(newValue: TransitionEffect): void {
    this.currentEffect = newValue;
  }

  private animateIn(): void {
    this.isVisible = true;
    this.animationProgress = 0;

    setTimeout(() => {
      this.startAnimation(0, 1, () => {
        this.onEnter?.();
        this.onTransitionEnd?.();
      });
    }, this.delay);
  }

  private animateOut(): void {
    this.startAnimation(1, 0, () => {
      this.isVisible = false;
      this.onExit?.();
      this.onTransitionEnd?.();
    });
  }

  private startAnimation(from: number, to: number, onComplete?: () => void): void {
    if (this.animationController) {
      this.animationController.stop();
    }

    this.animationController = Animator.create({
      duration: this.duration,
      easing: this.easing,
      delay: this.delay,
      iterations: 1,
      fill: FillMode.Forwards
    });

    this.animationController.onUpdate = (progress: number) => {
      this.animationProgress = from + (to - from) * progress;
    };

    this.animationController.onFinish = () => {
      onComplete?.();
    };

    this.animationController.play();
  }

  private getTransformStyle(): string {
    const progress = this.animationProgress;
    
    switch (this.currentEffect) {
      case TransitionEffect.SLIDE_LEFT:
        return `translateX(${(1 - progress) * 100}%)`;
      case TransitionEffect.SLIDE_RIGHT:
        return `translateX(${-(1 - progress) * 100}%)`;
      case TransitionEffect.SLIDE_UP:
        return `translateY(${(1 - progress) * 100}%)`;
      case TransitionEffect.SLIDE_DOWN:
        return `translateY(${-(1 - progress) * 100}%)`;
      case TransitionEffect.ZOOM_IN:
        return `scale(${0.8 + 0.2 * progress})`;
      case TransitionEffect.ZOOM_OUT:
        return `scale(${1.2 - 0.2 * progress})`;
      case TransitionEffect.ROTATE:
        return `rotate(${(1 - progress) * 180}deg)`;
      default:
        return 'none';
    }
  }

  private getOpacity(): number {
    switch (this.currentEffect) {
      case TransitionEffect.FADE:
        return this.animationProgress;
      case TransitionEffect.ZOOM_IN:
      case TransitionEffect.ZOOM_OUT:
        return this.animationProgress;
      default:
        return 1;
    }
  }

  build() {
    Stack() {
      ForEach(this.children, (child: CustomComponent, index: number) => {
        child
          .key(`animated-child-${index}`)
          .opacity(this.getOpacity())
          .transform(this.getTransformStyle())
          .animation({
            duration: this.duration,
            curve: this.easing,
            delay: this.delay
          })
      })
    }
    .visibility(this.isVisible ? Visibility.Visible : Visibility.Hidden)
  }

  private cleanup(): void {
    if (this.animationController) {
      this.animationController.stop();
      this.animationController = null;
    }
  }
}