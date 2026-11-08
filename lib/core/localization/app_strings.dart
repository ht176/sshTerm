enum AppLanguage {
  system,
  zh,
  en,
}

class AppStrings {
  final AppLanguage language;
  final bool isZh;

  const AppStrings(this.language)
      : isZh = language == AppLanguage.zh;

  // Navigation
  String get navHosts => isZh ? '主机' : 'Hosts';
  String get navKeys => isZh ? '密钥库' : 'Keys';
  String get navSnippets => isZh ? '快捷命令' : 'Snippets';
  String get navSettings => isZh ? '设置' : 'Settings';

  // Common
  String get cancel => isZh ? '取消' : 'Cancel';
  String get confirm => isZh ? '确定' : 'Confirm';
  String get save => isZh ? '保存' : 'Save';
  String get delete => isZh ? '删除' : 'Delete';
  String get edit => isZh ? '编辑' : 'Edit';
  String get copy => isZh ? '复制' : 'Copy';
  String get close => isZh ? '关闭' : 'Close';
  String get retry => isZh ? '重试' : 'Retry';
  String get required => isZh ? '必填项' : 'Required';

  // Hosts
  String get hostsTitle => isZh ? '主机资产' : 'Hosts';
  String get newHost => isZh ? '新建主机' : 'New Host';
  String get editHost => isZh ? '编辑主机' : 'Edit Host';
  String get searchHostsHint => isZh ? '搜索主机名、IP、用户名...' : 'Search hosts, IP, username...';
  String get allGroup => isZh ? '全部' : 'All';
  String get label => isZh ? '名称备注' : 'Label';
  String get labelHint => isZh ? '例如: 家中NAS, 生产服务器' : 'e.g. My Home NAS, Ubuntu Prod';
  String get hostname => isZh ? '主机地址 / IP' : 'Hostname / IP';
  String get port => isZh ? '端口' : 'Port';
  String get username => isZh ? '用户名' : 'Username';
  String get authMethod => isZh ? '认证方式' : 'Authentication Method';
  String get authPassword => isZh ? '密码认证' : 'Password';
  String get authKey => isZh ? '密钥认证' : 'SSH Key';
  String get password => isZh ? '登录密码' : 'Password';
  String get passwordHint => isZh ? '输入SSH登录密码' : 'Enter SSH password';
  String get selectKey => isZh ? '选择SSH密钥' : 'Select SSH Key Pair';
  String get noKeysPrompt => isZh ? '未找到可用密钥，请先在“密钥库”中生成或导入。' : 'No SSH keys found. Please generate or import a key in the Keys tab first.';
  String get groupTag => isZh ? '分组标签' : 'Group / Tag';
  String get groupHint => isZh ? '例如: NAS, 云服务器, 办公' : 'e.g. NAS, Cloud, Prod, Dev';
  String get colorTag => isZh ? '标记颜色' : 'Color Tag';
  String get icon => isZh ? '系统图标' : 'Icon';
  String get saveChanges => isZh ? '保存更改' : 'Save Changes';
  String get addHost => isZh ? '添加主机' : 'Add Host';
  String get quickConnect => isZh ? '快速连接' : 'Quick Connect';
  String get noHostsYet => isZh ? '暂无 SSH 主机' : 'No SSH Hosts Yet';
  String get noHostsDesc => isZh ? '添加您的 Linux 服务器、NAS 或云主机开启连接。' : 'Add your Linux server, NAS, or Cloud VPS to start.';
  String get addFirstHost => isZh ? '添加首台主机' : 'Add First Host';
  String get deleteHostTitle => isZh ? '删除主机' : 'Delete Host';
  String deleteHostConfirm(String label) => isZh ? '确认要删除主机“$label”吗？' : 'Are you sure you want to delete "$label"?';

  // Key Vault
  String get keyVaultTitle => isZh ? 'SSH 密钥保险箱' : 'Key Vault';
  String get newKeyPair => isZh ? '生成新密钥' : 'New Key Pair';
  String get importKey => isZh ? '导入私钥' : 'Import Key';
  String get generateNew => isZh ? '生成新密钥' : 'Generate New';
  String get importExisting => isZh ? '导入已有私钥' : 'Import Existing';
  String get keyTitle => isZh ? '密钥别名' : 'Key Title / Alias';
  String get keyTitleHint => isZh ? '例如: id_ed25519_prod' : 'e.g. id_ed25519_prod, macbook_key';
  String get keyAlgorithm => isZh ? '密钥算法' : 'Key Type / Algorithm';
  String get recommended => isZh ? '强烈推荐' : 'Recommended';
  String get ed25519Desc => isZh ? '极速且安全性最高' : 'Fastest & most secure';
  String get rsaDesc => isZh ? '传统老旧系统兼容性' : 'Legacy compatibility';
  String get keySize => isZh ? '密钥长度: ' : 'Key Size: ';
  String get pemContent => isZh ? '私钥 PEM 内容' : 'Private Key PEM Content';
  String get pemHint => isZh ? '粘贴完整的私钥内容 (-----BEGIN ...)' : 'Paste full private key (-----BEGIN ...)';
  String get passphraseOptional => isZh ? '保护密码 Passphrase (可选)' : 'Passphrase (Optional)';
  String get passphraseHint => isZh ? '留空则不设置保护密码' : 'Leave empty for no passphrase';
  String get copyPublicKey => isZh ? '复制公钥' : 'Copy Public Key';
  String get viewPublicKey => isZh ? '查看公钥' : 'View Public Key';
  String get deleteKey => isZh ? '删除密钥' : 'Delete Key';
  String get pubKeyCopied => isZh ? '公钥已复制到剪贴板！可直接粘贴至 authorized_keys。' : 'Public key copied to clipboard! Paste into authorized_keys.';
  String get noKeysYet => isZh ? '暂无 SSH 密钥' : 'No SSH Keys Yet';
  String get noKeysDesc => isZh ? '一键生成高安全 Ed25519/RSA 密钥，或导入您的已有私钥。' : 'Generate Ed25519/RSA keys or import your existing private key.';
  String get deleteKeyConfirm => isZh ? '确认删除此密钥对？关联的主机可能无法登录。' : 'Are you sure you want to delete this key? Associated hosts may fail to connect.';

  // Terminal
  String connectingTo(String user, String host, int port) => isZh ? '正在连接至 $user@$host:$port...' : 'Connecting to $user@$host:$port...';
  String get connected => isZh ? '已建立连接' : 'Connected';
  String get disconnected => isZh ? '连接已断开' : 'Disconnected';
  String get reconnect => isZh ? '重新连接' : 'Reconnect';
  String get decreaseFont => isZh ? '缩小字体' : 'Decrease font size';
  String get increaseFont => isZh ? '放大字体' : 'Increase font size';
  String get snippetsDrawer => isZh ? '常用命令抽屉' : 'Snippets / Quick Commands';
  String get hostVerificationTitle => isZh ? '主机指纹真实性确认' : 'Host Authenticity Verification';
  String hostVerificationPrompt(String host, int port) => isZh
      ? '无法自动确认主机 "$host:$port" 的真实性，请核对指纹以防中间人劫持：'
      : 'The authenticity of host "$host:$port" cannot be established automatically:';
  String get trustAndConnect => isZh ? '信任并连接' : 'Trust & Connect';

  // Snippets
  String get snippetsTitle => isZh ? '快捷命令' : 'Snippets';
  String get newSnippet => isZh ? '新建命令' : 'New Snippet';
  String get editSnippet => isZh ? '编辑命令' : 'Edit Snippet';
  String get snippetTitle => isZh ? '命令标题' : 'Snippet Title';
  String get snippetTitleHint => isZh ? '例如: 重启Docker服务, 查看系统日志' : 'e.g. Restart Docker Engine';
  String get snippetCommand => isZh ? 'Shell 脚本 / 指令' : 'Command / Script';
  String get snippetCategory => isZh ? '分类' : 'Category';
  String get noSnippetsYet => isZh ? '暂无快捷命令' : 'No Snippets Yet';
  String get noSnippetsDesc => isZh ? '保存高频运维 Shell 指令，在终端中一键点按执行。' : 'Save frequently used shell commands for one-tap execution in terminal.';
  String get commandCopied => isZh ? '命令已复制到剪贴板！' : 'Command copied to clipboard!';
  String deleteSnippetConfirm(String title) => isZh ? '确认要删除命令“$title”吗？' : 'Are you sure you want to delete "$title"?';

  // Settings & Auto Update
  String get terminalAppearance => isZh ? '终端外观与字体' : 'Terminal Appearance';
  String get fontSize => isZh ? '字号大小' : 'Font Size';
  String get securitySettings => isZh ? '安全与主机认证' : 'Security & Host Verification';
  String get knownHosts => isZh ? '已信任的主机指纹库' : 'Known Host Fingerprints';
  String knownHostsCount(int n) => isZh ? '$n 条已信任记录' : '$n trusted host keys in store';
  String get clearKnownHosts => isZh ? '清除缓存' : 'Clear';
  String get clearKnownHostsConfirm => isZh ? '清除后，再次连接已知主机将重新提示指纹验证。' : 'All saved host fingerprints will be forgotten. You will be prompted on next connection.';
  String get keyEncryptionNotice => isZh ? '密钥硬件安全隔离' : 'Key Storage Encryption';
  String get keyEncryptionDesc => isZh ? '私钥受系统 Keychain / Keystore 硬件级加密防护' : 'Private keys secured by iOS Keychain / Android Keystore';
  String get languageSetting => isZh ? '软件语言' : 'Language';
  String get languageSystem => isZh ? '跟随系统' : 'System Default';
  String get languageZh => isZh ? '简体中文' : '简体中文 (Chinese)';
  String get languageEn => isZh ? 'English' : 'English';
  String get aboutSection => isZh ? '关于与更新' : 'About & Updates';
  String get currentVersion => isZh ? '当前版本' : 'Current Version';
  String get checkForUpdates => isZh ? '检查更新' : 'Check for Updates';
  String get checkingUpdates => isZh ? '正在检查最新版本...' : 'Checking for updates...';
  String get alreadyLatest => isZh ? '当前已是最新版本！' : 'You are running the latest version!';
  String get newVersionFound => isZh ? '发现新版本' : 'New Version Available';
  String get updateNow => isZh ? '立即下载更新' : 'Download Update';
  String get updateLater => isZh ? '稍后' : 'Later';
  String get autoCheckUpdates => isZh ? '启动时自动检测更新' : 'Auto Check on Launch';
  String get releaseNotes => isZh ? '更新日志' : 'Release Notes';
}
