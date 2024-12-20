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
      data=JSON.parse(info)
      logger.debug "update called"
      ActiveRecord::Base.transaction do
        data.each{ |value|
          @sleep=Sleep.where("date=?",value['date'])
          @sleep.update(wake: value['wake'],bath: value['bath'],bed: value['bed'],sleep_in: value['sleep_in'],sleep: value['sleep'],deep_sleep: value['deep_sleep'],description: value['description'])
        }
      end
    rescue => e
      logger.fatal e
    end
  end
end
