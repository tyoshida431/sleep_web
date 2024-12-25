require 'date'

class SleepController < ApplicationController
  # 一時で無効にする
  protect_from_forgery with: :null_session
  def index
    begin
      # 指定の日付をGETパラメーターから取得する。
      year_month=params[:month]
      # 睡眠一覧を取得します。
      sleeps=Sleep.get_list(year_month)
    rescue => e
      logger.fatal e
      sleeps=[]
    end
    # TODO : result_code, listの形式にする。
    render json: sleeps
  end

  def update()
    begin
      info=request.raw_post
      sleeps=JSON.parse(info)
      Sleep.update(sleeps)
    rescue => e
      logger.fatal e
    end
  end
end
