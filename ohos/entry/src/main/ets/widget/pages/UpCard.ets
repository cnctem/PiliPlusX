const storage = new LocalStorage();

@Entry(storage)
@Component
struct UpCard {
  @LocalStorageProp('mid') mid: string = '';
  @LocalStorageProp('name') name: string = '';
  @LocalStorageProp('avatar') avatar: string = '';
  @LocalStorageProp('topPhoto') topPhoto: string = '';
  @LocalStorageProp('latestTitle') latestTitle: string = '';
  @LocalStorageProp('latestTime') latestTime: string = '';
  @LocalStorageProp('latestLength') latestLength: string = '';

  build() {
    Stack() {
      if (this.topPhoto !== '') {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Image(this.topPhoto)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
          // 渐变蒙版：左侧100%透明（不遮挡内容），右侧保留可见度
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 135,
              colors: [
                [$r('app.color.up_card_mask_start'), 0],
                [$r('app.color.up_card_mask_start'), 0.25],
                [$r('app.color.up_card_mask_mid'), 0.65],
                [$r('app.color.up_card_mask_end'), 1],
              ],
            })
        }
        .width('70%')
        .height('96%')
        .position({ x: '30%', y: '4%' })
      }

      // 头像固定居左，名字与最近更新居左排列，最近更新为灰色小字
      Row({ space: 8 }) {
        Image(this.avatar)
          .width(36)
          .height(36)
          .borderRadius(18)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.icon_startwindow'))
        Column({ space: 3 }) {
          Text(this.name)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.latestTitle === '' ? '最近暂无更新' : this.latestTitle)
            .fontSize(10)
            .opacity(0.65)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.latestTime !== '') {
            Text(this.latestTime + (this.latestLength !== '' ? ' · ' + this.latestLength : ''))
              .fontSize(9)
              .opacity(0.45)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 8, top: 12, bottom: 12 })
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            pili_up_card: '1',
            mid: this.mid,
          },
        });
      })
    }
    .width('100%')
    .height('100%')
  }
}

