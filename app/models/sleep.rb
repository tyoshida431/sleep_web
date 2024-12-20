class Sleep < ApplicationRecord
  def self.get_list(year_month)
    begin
      # 指定の日付をGETパラメーターから取得する。
      # なければ今月を指定する。
      #year_month=params[:month]
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
      sleeps=self.where("date>=? AND date<=?",first_day,last_day)
      # もしレコードが月末まで足りなかったらinsertします。
      # 新しい月の場合も月末まで足りないと判定してinsertします。
      if is_fragment(sleeps,year_month) then
        # クライアントからGETが走るので返さない。
        insert_new_month(sleeps,year_month)
      end
    rescue => e
      logger.fatal e
      sleeps=[]
    end
    return sleeps
  end

  def self.is_fragment(sleeps,year_month)
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

  def self.insert_new_month(sleeps,year_month)
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
    last_day_fragment=last_day.to_s[9,2].to_i
    last_day_for_month_day=last_day_for_month[2].to_i
    insert_sleeps=[]
    while last_day_fragment!=last_day_for_month_day do
      last_day_fragment=last_day_fragment+1
      last_day_fragment_pad=last_day_fragment.to_s
      if last_day_fragment_pad.length==1 then
        last_day_fragment_pad="0"+last_day_fragment_pad
      end
      day=year+"-"+month+"-"+last_day_fragment_pad
      insert_sleeps << {date: day,wake: 0,bath: 0,bed: 0,sleep_in: "",sleep: "",deep_sleep: "",description: ""}
    end
    ActiveRecord::Base.transaction do
      self.insert_all(insert_sleeps)
    end
  end
end
