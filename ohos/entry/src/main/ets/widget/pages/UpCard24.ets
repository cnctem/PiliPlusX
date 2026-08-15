const up24Storage = new LocalStorage();

interface UpItem {
  bvid: string;
  title: string;
  created: number;
  pic: string;
  picUrl: string;
  time: string;
}

@Entry(up24Storage)
@Component
struct UpCard24 {
  @LocalStorageProp('mid') mid: string = '';
  @LocalStorageProp('name') name: string = '';
  @LocalStorageProp('avatar') avatar: string = '';
  @LocalStorageProp('topPhoto') topPhoto: string = '';
  @LocalStorageProp('uploadsJson') uploadsJson: string = '[]';

  private uploads(): UpItem[] {
    try {
      const parsed = JSON.parse(this.uploadsJson) as UpItem[];
      if (Array.isArray(parsed)) {
        return parsed;
      }
    } catch (e) {
    }
    return [];
  }

  private itemOf(index: number): UpItem | null {
    const arr = this.uploads();
    if (index < arr.length) {
      return arr[index];
    }
    return null;
  }

  private picOf(index: number): string {
    const it = this.itemOf(index);
    return it === null ? '' : it.pic;
  }

  private titleOf(index: number): string {
    const it = this.itemOf(index);
    return it === null ? '' : it.title;
  }

  private timeOf(index: number): string {
    const it = this.itemOf(index);
    return it === null ? '' : (it.time ?? '');
  }

  private bvidOf(index: number): string {
    const it = this.itemOf(index);
    return it === null ? '' : (it.bvid ?? '');
  }

  private openVideo(index: number): void {
    const bvid = this.bvidOf(index);
    if (bvid.length > 0) {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          pili_up_card: '1',
          bvid: bvid,
        },
      });
    } else {
      this.openUp();
    }
  }

  private openUp(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        pili_up_card: '1',
        mid: this.mid,
      },
    });
  }

  build() {
    Stack() {
      if (this.topPhoto !== '') {
        Image(this.topPhoto)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
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

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Image(this.avatar)
            .width(26)
            .height(26)
            .borderRadius(13)
            .objectFit(ImageFit.Cover)
            .alt($r('app.media.icon_startwindow'))
          Text(this.name)
            .fontSize("48px")
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Blank()
          Column() {
            SymbolGlyph($r('sys.symbol.arrow_clockwise'))
              .fontSize('38px')
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .backgroundColor('#30808080')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: { refresh: '1' },
            });
          })
        }
        .width('100%')

        Row({ space: 6 }) {
          this.VideoCell(0)
          this.VideoCell(1)
          this.VideoCell(2)
        }
        .alignItems(VerticalAlign.Top)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    }
    .onClick(() => {
      this.openUp();
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  VideoCell(index: number) {
    Column({ space: 2 }) {
      if (this.picOf(index).length > 0) {
        Image(this.picOf(index))
          .width('100%')
          .height(65)
          .borderRadius(9)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.icon_startwindow'))
      } else {
        Column()
          .width('100%')
          .height(65)
          .borderRadius(9)
          .linearGradient({
            angle: 135,
            colors: [
              [$r('app.color.up_card_mask_start'), 0],
              [$r('app.color.up_card_mask_end'), 1],
            ],
          })
      }
      Row() {
        Text(this.titleOf(index))
          .fontSize("36px")
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity(0.9)
      }
      .height(25)
      .alignItems(VerticalAlign.Top)
      Text(this.timeOf(index))
        .fontSize("30px")
        .maxLines(1)
        .opacity(0.5)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openVideo(index);
    })
  }
}
