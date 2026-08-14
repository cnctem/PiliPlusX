const miniStorage = new LocalStorage();

@Entry(miniStorage)
@Component
struct UpCardMini {
  @LocalStorageProp('mid') mid: string = '';
  @LocalStorageProp('name') name: string = '';
  @LocalStorageProp('avatar') avatar: string = '';

  build() {
    Row({ space: 8 }) {
      Image(this.avatar)
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.icon_startwindow'))
      Text(this.name)
        .fontSize("40px")
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 10, right: 8 })
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
}
