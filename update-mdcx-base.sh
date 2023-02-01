#!/bin/bash

. .env.versions

# 临时存放应用源码的目录
DIR_APP_RAW="app-raw"
rm -rf $DIR_APP_RAW
# DIR_APP_RAW=.app_raw_$(head /dev/urandom |cksum |md5sum |cut -c 1-20)

compareVersion () {
  if [[ $1 == $2 ]]
  then
    return 0
  fi
  local IFS=.
  local i ver1=($1) ver2=($2)
  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
  do
    ver1[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++))
  do
    if [[ -z ${ver2[i]} ]]
    then
      # fill empty fields in ver2 with zeros
      ver2[i]=0
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]}))
    then
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      return 2
    fi
  done
  return 0
}

# TMP_FILE=.$(head /dev/urandom |cksum |md5sum |cut -c 1-20)

CONTENT=$(curl "https://api.github.com/repos/anyabc/something/releases/latest")

URL=$(echo $CONTENT | grep -oi 'https://[a-zA-Z0-9./?=_%:-]*MDCx-py-[a-z0-9]\+.[a-z]\+')

if [[ -z "$URL" ]]; then
  echo "❌ 获取新版下载链接失败！"
  exit
fi

echo "🔗 下载链接：$URL"

FILENAME=$(echo $URL | grep -oi 'MDCx-py-[a-z0-9]\+.[a-z]\+')
EXTENSION=$(echo $FILENAME | grep -oi '[a-z]\+$')
VERSION=$(echo $FILENAME | sed 's/MDCx-py-//g' | sed 's/.[a-z]\+//g')
PURE_FILENAME=$(echo $URL | grep -oi 'MDCx-py-[a-z0-9]\+')

echo "⭕️ 文件名：$PURE_FILENAME"
echo "⭕️ 后缀名：$EXTENSION"
echo "⭕️ 已发布的最新版本：$VERSION"
echo "⭕️ 本地版本：$MD_MDCX_VERSION"

# exit

compareVersion $VERSION $MD_MDCX_VERSION
case $? in
  0) op='=';;
  1) op='>';;
  2) op='<';;
esac

if [[ $op == '>' ]]; then
  echo "🆕 已发布的最新版本 较新于 本地版本"

  mkdir -p ./$DIR_APP_RAW
  cd ./$DIR_APP_RAW

  # echo "✅ 清空 ./$DIR_APP_RAW 目录"
  # rm -rf ./$DIR_APP_RAW/*

  echo "⭕️ 下载新版..."
  curl -o $VERSION.rar $URL -L
  echo "✅ 下载成功。开始解压到 ./$DIR_APP_RAW 目录"

  UNRAR_PATH=$(which unrar)
  if [[ -z "$UNRAR_PATH" ]]; then
    echo "❌ 没有unrar命令！"
  else
    # 解压
    unrar x -o+ $VERSION.rar
    # 暂时没发现unrar有类似tar的stip-components这样的参数，
    # 所以解压时会带有项目根目录，需要将目录里的文件复制出来
    cp -rfp $PURE_FILENAME/* .
    # 删除压缩包
    rm -f $VERSION.rar
    # 删除解压出来的目录
    rm -rf $PURE_FILENAME
    echo "✅ 解压成功！"
  fi
else
  if [[ $op == '<' ]]; then
    echo "🍵 本地版本 较新于 已发布的最新版本"
  else
    echo "🍵 本地版本 已是最新版本"
  fi
fi