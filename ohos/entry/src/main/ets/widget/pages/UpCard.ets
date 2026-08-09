const storage = new LocalStorage();

@Entry(storage)
@Component
struct UpCard {
  @LocalStorageProp('mid') mid: string = '';
  @LocalStorageProp('name') name: string = '';
  @LocalStorageProp('avatar') avatar: string = '';

  build() {
    Row({ space: 8 }) {
      Image(this.avatar)
        .width(36)
        .height(36)
        .borderRadius(18)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.icon_startwindow'))
      Text(this.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .justifyContent(FlexAlign.Center)
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
