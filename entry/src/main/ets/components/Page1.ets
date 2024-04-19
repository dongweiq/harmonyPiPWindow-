/**
 *
 * @author 王洪贺
 * @date 2024/4/18 16:43
 */

// Page1.ets
// 该页面用于展示画中画功能的基本使用
import pipWindow from '@ohos.PiPWindow'; // 引入PiPWindow模块
import AvPlayManage from '../videomanager/AvPlayManager'; // 请自行实现视频播放的相关开发
import { BusinessError } from '@ohos.base';
import { media } from '@kit.MediaKit';

const TAG = 'Page1';

@Component
export struct Page1 {
  @Consume('pageInfos') pageInfos: NavPathStack;
  private surfaceId: string = ''; // surfaceId，用于关联XComponent与视频播放器
  private mXComponentController: XComponentController = new XComponentController();
  private player?: AvPlayManage = undefined;
  private pipController?: pipWindow.PiPController = undefined;
  navId: string = '';

  build() {
    NavDestination() {
      Column() {
        // XComponent控件，用于播放视频流
        XComponent({ id: 'pipDemo', type: 'surface', controller: this.mXComponentController })
          .onLoad(() => {
            this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
            // 需要设置AVPlayer的surfaceId为XComponentController的surfaceId
            this.player = new AvPlayManage();
            this.player.initPlayer(this.surfaceId, (avPlayer: media.AVPlayer) => {

            })
            this.player.videoPlay()
            // this.player.avPlayerFdSrcDemo();
          })
          .onDestroy(() => {
            console.info(`[${TAG}] XComponent onDestroy`);
          })
          .size({ width: '100%', height: '800px' })
        Row({ space: 20 }) {
          Button('start')// 启动画中画
            .onClick(() => {
              this.startPip();
            })
            .stateStyles({
              pressed: {
                .backgroundColor(Color.Red);
              },
              normal: {
                .backgroundColor(Color.Blue);
              }
            })
          Button('stop')// 停止画中画
            .onClick(() => {
              this.stopPip();
            })
            .stateStyles({
              pressed: {
                .backgroundColor(Color.Red);
              },
              normal: {
                .backgroundColor(Color.Blue);
              }
            })
          Button('updateSize')// 更新视频尺寸
            .onClick(() => {
              // 此处设置的宽高应为媒体内容宽高，需要通过媒体相关接口或回调获取
              // 例如使用AVPlayer播放视频时，可通过videoSizeChange回调获取媒体源更新后的尺寸
              this.updateContentSize(900, 1600);
            })
            .stateStyles({
              pressed: {
                .backgroundColor(Color.Red);
              },
              normal: {
                .backgroundColor(Color.Blue);
              }
            })
        }
        .size({ width: '100%', height: 60 })
        .justifyContent(FlexAlign.SpaceAround)
      }
      .justifyContent(FlexAlign.Center)
      .height('100%')
      .width('100%')
    }
  }

  startPip() {
    if (!pipWindow.isPiPEnabled()) {
      console.error(`picture in picture disabled for current OS`);
      return;
    }
    let config: pipWindow.PiPConfiguration = {
      context: getContext(this),
      componentController: this.mXComponentController,
      // 当前page导航id
      // 1、UIAbility使用Navigation管理页面，需要设置Navigation控件的id属性，并将该id设置给画中画控制器，确保还原场景下能够从画中画窗口恢复到原页面
      // 2、UIAbility使用Router管理页面时（画中画场景不推荐该导航方式），无需设置navigationId。注意：该场景下启动画中画后，不要进行页面切换，否则还原场景可能出现异常
      // 3、UIAbility只有单页面时，无需设置navigationId，还原场景下也能够从画中画窗口恢复到原页面
      navigationId: this.navId,
      templateType: pipWindow.PiPTemplateType.VIDEO_PLAY, // 对于视频通话、视频会议等场景，需要设置相应的模板类型
      contentWidth: 800, // 可选，创建画中画控制器时系统可通过XComponent组件大小设置画中画窗口比例
      contentHeight: 600, // 可选，创建画中画控制器时系统可通过XComponent组件大小设置画中画窗口比例
    };
    // 步骤1：创建画中画控制器，通过create接口创建画中画控制器实例
    let promise: Promise<pipWindow.PiPController> = pipWindow.create(config);
    promise.then((controller: pipWindow.PiPController) => {
      this.pipController = controller;
      // 步骤1：初始化画中画控制器
      this.initPipController();
      // 步骤2：通过startPiP接口启动画中画
      this.pipController.startPiP().then(() => {
        console.info(`Succeeded in starting pip.`);
      }).catch((err: BusinessError) => {
        console.error(`Failed to start pip. Cause:${err.code}, message:${err.message}`);
      });
    }).catch((err: BusinessError) => {
      console.error(`Failed to create pip controller. Cause:${err.code}, message:${err.message}`);
    });
  }

  initPipController() {
    if (!this.pipController) {
      return;
    }
    // 步骤1：通过setAutoStartEnabled接口设置是否需要在应用返回桌面时自动启动画中画，注册stateChange和controlPanelActionEvent回调
    this.pipController.setAutoStartEnabled(false /*or true if necessary*/); // 默认为false
    this.pipController.on('stateChange', (state: pipWindow.PiPState, reason: string) => {
      this.onStateChange(state, reason);
    });
    this.pipController.on('controlPanelActionEvent', (event: pipWindow.PiPActionEventType) => {
      this.onActionEvent(event);
    });
  }

  onStateChange(state: pipWindow.PiPState, reason: string) {
    let curState: string = '';
    switch (state) {
      case pipWindow.PiPState.ABOUT_TO_START:
        curState = "ABOUT_TO_START";
        break;
      case pipWindow.PiPState.STARTED:
        curState = "STARTED";
        break;
      case pipWindow.PiPState.ABOUT_TO_STOP:
        curState = "ABOUT_TO_STOP";
        break;
      case pipWindow.PiPState.STOPPED:
        curState = "STOPPED";
        break;
      case pipWindow.PiPState.ABOUT_TO_RESTORE:
        curState = "ABOUT_TO_RESTORE";
        break;
      case pipWindow.PiPState.ERROR:
        curState = "ERROR";
        break;
      default:
        break;
    }
    console.info(`[${TAG}] onStateChange: ${curState}, reason: ${reason}`);
  }

  onActionEvent(event: pipWindow.PiPActionEventType) {
    switch (event) {
      case 'playbackStateChanged':
      // 开始或停止视频
        this.player?.videoPause()
        break;
      case 'nextVideo':
      // 播放上一个视频
        this.player?.videoChoose('test2.mp4', 0, (avPlayer: media.AVPlayer) => {
        });
        break;
      case 'previousVideo':
      // 播放下一个视频
        this.player?.videoChoose('test1.mp4', 0, (avPlayer: media.AVPlayer) => {
        });
        break;
      default:
        break;
    }
  }

  // 步骤3：视频内容变化时，向画中画控制器更新视频尺寸信息，用于调整画中画窗口比例
  updateContentSize(width: number, height: number) {
    if (this.pipController) {
      this.pipController.updateContentSize(width, height);
    }
  }

  // 步骤4：当不再需要显示画中画时，通过stopPiP接口关闭画中画
  stopPip() {
    if (this.pipController) {
      let promise: Promise<void> = this.pipController.stopPiP();
      promise.then(() => {
        console.info(`Succeeded in stopping pip.`);
        this.pipController?.off('stateChange'); // 如果已注册stateChange回调，停止画中画时取消注册该回调
        this.pipController?.off('controlPanelActionEvent'); // 如果已注册controlPanelActionEvent回调，停止画中画时取消注册该回调
      }).catch((err: BusinessError) => {
        console.error(`Failed to stop pip. Cause:${err.code}, message:${err.message}`);
      });
    }
  }
}