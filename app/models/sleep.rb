class Sleep < ApplicationRecord
  def self.get_list(year_month)
    begin
      # 指定の日付をGETパラメーターから取得する。
      # なければ今月を指定する。
      year=0
      month=0
      # 今月を指定します。
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
      sleeps=self.where("date>=? AND date<=?",first_day,last_day)
      # 新しい月の場合判定してinsertします。
      if is_new_month(sleeps) then
        # クライアントからGETが走るので返さない。
        # クライアントからGETが走らなくなったので返します。2026/06/08.
        insert_new_month(sleeps,year_month)
        sleeps=self.where("date>=? AND date<=?",first_day,last_day)
      end
    rescue => e
      logger.fatal "一覧取得失敗"
      logger.fatal e
      sleeps=[]
    end
    return sleeps
  end

  def self.is_new_month(sleeps)
    ret=true
    if sleeps.length==0 then
      ret=true
    else
      ret=false
    end
    return ret
  end

  def self.insert_new_month(sleeps,year_month)
    # 月末まで一覧します。
    year=year_month[0,4]
    month=year_month[4,2]
    # 月頭から決め打ちで00から始めて1日から作る
    first_day=year+"00"
    last_day=Date.new(year.to_i,month.to_i,-1).strftime("%Y-%m-%d").split("-")
    first_day_num=first_day.to_s[9,2].to_i
    last_day_num=last_day[2].to_i
    insert_sleeps=[]
    while first_day_num!=last_day_num do
      first_day_num=first_day_num+1
      first_day_fragment_pad=first_day_num.to_s
      if first_day_fragment_pad.length==1 then
        first_day_fragment_pad="0"+first_day_fragment_pad
      end
      day=year+"-"+month+"-"+first_day_fragment_pad
      insert_sleeps << {date: day,wake: 0,bath: 0,bed: 0,sleep_in: "",sleep: "",deep_sleep: "",description: ""}
    end
    ActiveRecord::Base.transaction do
      self.insert_all(insert_sleeps)
    end
  end
  def self.update(sleeps)
    begin
      ActiveRecord::Base.transaction do
        sleeps.each{ |value|
          @sleep=Sleep.where("date=?",value['date'])
          @sleep.update!(wake: value['wake'],bath: value['bath'],bed: value['bed'],sleep_in: value['sleep_in'],sleep: value['sleep'],deep_sleep: value['deep_sleep'],description: value['description'])
        }
      end
    rescue => e
      logger.fatal "更新失敗"
      logger.fatal e
    end
  end
end
