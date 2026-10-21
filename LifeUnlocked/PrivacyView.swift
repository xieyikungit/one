import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section("数据存放") {
                Text("人生经历、目标和档案默认保存在此设备，可随系统设备备份保存。Apple 健康步数单独缓存在本机，不进入系统设备备份。应用不要求账号，也没有开发者服务器。")
                Text("请定期导出 JSON 备份。备份包含手动记录、目标和档案，不包含 Apple 健康步数；恢复后可以重新授权同步步数。")
            }
            Section("Apple 健康") {
                Text("只有在你主动连接后，应用才读取每日步数，用于运动经验、徽章和回顾。应用不会写入健康数据，也不会把步数用于广告。")
            }
            Section("地点与导出") {
                Text("记录城市时，应用可能使用 Apple 地图服务解析城市位置；不会读取实时定位。手动导出的文件可能包含你填写的敏感经历，请自行选择保存位置和分享对象。")
            }
            Section("你的控制权") {
                Link("查看完整隐私政策", destination: URL(string: "https://github.com/xieyikungit/one/blob/main/PRIVACY.md")!)
                Link("获取帮助", destination: URL(string: "https://github.com/xieyikungit/one/blob/main/SUPPORT.md")!)
                Button("清除本机所有数据", role: .destructive) { confirmDelete = true }
            }
        }
        .navigationTitle("隐私与数据")
        .confirmationDialog("清除所有本机数据？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("确认清除", role: .destructive) { store.deleteAllLocalData() }
            Button("取消", role: .cancel) { }
        } message: {
            Text("这会删除经历、目标、档案、健康步数缓存和导入前快照。已导出到其他位置的文件不会删除。")
        }
    }
}
