require 'date'

class SleepController < ApplicationController
  # 一時で無効にする
  protect_from_forgery with: :null_session
  def index
    begin
      # 指定の日付をGETパラメーターから取得する。
      # なければ今月を指定する。
      #logger.debug params
      year_month=params[:month]
      # 今月を指定します。
      year=0
      month=0
      if year_month==nil then
        today=DateTime.now.to_s
        year_month=""
        year_month+=today[0,4] 
        year_month+=today[5,2]
      end
      # 指定の日付の一覧を取得する。
      year=year_month[0,4].to_i
      month=year_month[4,2].to_i
      # 月初めと月最後
      first_day=Date.new(year.to_i,month.to_i).strftime("%Y-%m-%d")
      last_day=Date.new(year.to_i,month.to_i,-1).strftime("%Y-%m-%d")
      #logger.debug first_day
      #logger.debug last_day
      #@sleeps=Sleep.all
      sleeps=Sleep.where("date>=? AND date<=?",first_day,last_day)
      # もしレコードが月末まで足りなかったらinsertします。
      # 新しい月の場合も月末まで足りないと判定してinsertします。
      if is_fragment(sleeps,year_month) then
        # クライアントからGETが走るので返さない。
        #sleeps=insert_new_month(sleeps,year_month)
        insert_new_month(sleeps,year_month)
      end
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
      #logger.debug data
      #data.each{ |value|
        #logger.debug value
        #logger.debug value['date']
        #update_sleeps << value
        #logger.debug value
        #update_sleeps << {date: key['date'],wake: key['wake'],bath: key['bath'],bed: key['bath'],sleep_in: key['sleep_in'],sleep: key['sleep'],deep_sleep: key['deep_sleep'],description: key['description']} 
      #}
      logger.debug "update called"
      #logger.debug update_sleeps
      ActiveRecord::Base.transaction do
        data.each{ |value|
          #logger.debug value
          #logger.debug value['date']
          #logger.debug value['wake']
          @sleep=Sleep.where("date=?",value['date'])
          @sleep.update(wake: value['wake'],bath: value['bath'],bed: value['bed'],sleep_in: value['sleep_in'],sleep: value['sleep'],deep_sleep: value['deep_sleep'],description: value['description'])
        }
        #Sleep.update_all(update_sleeps)
      end
    rescue => e
      logger.fatal e
    end
  end

  def is_fragment(sleeps,year_month)
    ret=true
    # sleepsの長さが0だったら半端であると返す。
    if sleeps.length!=0 then
      sleep=sleeps[-1] 
      last_day=sleep.date
      # 年、月を取得する。
      year=year_month[0,4]
      month=year_month[4,2]
      # 対象年月日の月末を取得する。
      # 一ヶ月書けてなくて新しく挿入する場合を考える。
      # あるいは今月新しく始める程度か。今月新しく始めて良いかもしれない。
      # 毎日徹夜続きで半端にしか書けない人もいるかも知れない。
      last_day_for_month=Date.new(year.to_i,month.to_i,-1).strftime("%Y-%m-%d").split("-")
      year_last_day=last_day_for_month[0] 
      month_last_day=last_day_for_month[1]
      day_last_day=last_day_for_month[2]

      # DBから取得したデーターを整形する。
      last_day_from_db=last_day.to_s.split("-")
      year_db=last_day_from_db[0]
      month_db=last_day_from_db[1]
      day_db=last_day_from_db[2]

      # 比較する。
      if year_last_day==year_db and month_last_day==month_db and day_last_day==day_db then
        ret=false
      end
    end 
    return ret
  end

  def insert_new_month(sleeps,year_month)
    # 足りないところから月末まで一覧します。
    year=year_month[0,4]
    month=year_month[4,2]
    last_sleep=sleeps[-1]
    if last_sleep==nil then
      # 00から始めて1日から作る
      last_day=year+"00"
    else
      last_day=last_sleep.date
    end
    last_day_for_month=Date.new(year.to_i,month.to_i,-1).strftime("%Y-%m-%d").split("-")
    #logger.debug last_day
    last_day_fragment=last_day.to_s[9,2].to_i
    #logger.debug last_day_fragment
    last_day_for_month_day=last_day_for_month[2].to_i
    #logger.debug last_day_fragment
    #logger.debug last_day_for_month_day
    insert_sleeps=[]
    #ret_sleeps=[]
    while last_day_fragment!=last_day_for_month_day do
      last_day_fragment=last_day_fragment+1
      #logger.debug last_day_fragment
      last_day_fragment_pad=last_day_fragment.to_s
      if last_day_fragment_pad.length==1 then
        last_day_fragment_pad="0"+last_day_fragment_pad
      end
      day=year+"-"+month+"-"+last_day_fragment_pad
      #logger.debug day
      insert_sleeps << {date: day,wake: 0,bath: 0,bed: 0,sleep_in: "",sleep: "",deep_sleep: "",description: ""}
    #  sleep=Sleep.new
    #  sleep.date=day
    #  sleep.wake=0
    #  sleep.bath=0
    #  sleep.bed=0
    #  sleep.sleep_in=""
    #  sleep.sleep=""
    #  sleep.deep_sleep=""
    #  sleep.description=""
    #  ret_sleeps.push(sleep)
    end
    #logger.debug insert_sleeps.length
    #insert_sleeps.each do |sleep|
    #  Sleep.create(sleep)
    #end
    #insert_sleeps.each do |sleep|
    #  logger.debug sleep
    #end
    ActiveRecord::Base.transaction do
      Sleep.insert_all(insert_sleeps)
    end
    #logger.debug sleeps.length
    #logger.debug sleeps 
    #if sleeps.length==0 then
    #  return ret_sleeps
    #else
    #  ret_sleeps.each do |sleep|
    #    sleeps.push(sleep)
    #  end
    #  return sleeps
    #end
  end
end
