
module JIJI

  class AbstractError < StandardError
    def initialize( code, message="", info={}  )
      super( message )
      @code = code
      @info = info
    end
    def detail
      {"code"=>@code,"info"=>@info}
    end
    attr :code
    attr :info, true
  end

  # 致命的エラー
  class FatalError < AbstractError
    def initialize( code, message="", info={}  )
      super
    end
  end
  # ユーザー操作により発生しうるエラー
  class UserError < AbstractError
    def initialize( code, message="", info={} )
      super
    end
  end

  # エラーコード:存在しない
  ERROR_NOT_FOUND = "not_found"
  # エラーコード:すでに存在する
  ERROR_ALREADY_EXIST = "already_exist"
  # エラーコード:ファイルでない
  ERROR_IS_NOT_FILE = "is_not_file"
  # エラーコード:フォルダでない
  ERROR_IS_NOT_FOLDER = "is_not_folder"

  # エラーコード:不正な名前
  ERROR_ILLEGAL_NAME = "illegal_name"
  # エラーコード:不正な引数
  ERROR_ILLEGAL_ARGUMENTS = "illegal_arguments"

  # エラーコード:想定外エラー
  ERROR_FATAL = "fatal"

  # エラーコード:サーバーに接続されていない
  ERROR_NOT_CONNECTED = "not_connected"
end