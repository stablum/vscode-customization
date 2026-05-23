scoop install vscode
code --install-extension openai.chatgpt
code --install-extension subframe7536.custom-ui-style
code --install-extension vscodevim.vim

# code --install-extension 2048Labs.linesight
$linesight_path = Join-Path $HOME '\Projects\LineSight\linesight-latest.vsix'
code --install-extension $linesight_path

code --list-extensions --show-versions

