require 'openstudio'
require 'openstudio-standards'

def load_test_model
  test_osm = "./tests/in.osm"
  vt = OpenStudio::OSVersion::VersionTranslator.new
  model = vt.loadModel(test_osm)
  if model.empty?
    puts "Couldn't open model"
  else
    model = model.get
  end
  return model
end

def check_tstat_schedules(model)
  # collects all thermostat schedules and returns the start/end hours, min/max setpoint temps
  tstat_groups = []
  model.getThermalZones.each do |zone|
    tstat_info = {}
    zone_name = zone.name.get
    tstat_info[:zone_name] = zone_name
    if zone.thermostatSetpointDualSetpoint.is_initialized
      tstat = zone.thermostatSetpointDualSetpoint.get
      if tstat.heatingSetpointTemperatureSchedule.is_initialized
        tstat_info[:heat_sch] = tstat.heatingSetpointTemperatureSchedule.get
      else
        tstat_info[:heat_sch] = nil
      end
      if tstat.coolingSetpointTemperatureSchedule.is_initialized
        tstat_info[:cool_sch] = tstat.coolingSetpointTemperatureSchedule.get
      else
        tstat_info[:cool_sch] = nil
      end
    else
      tstat_info[:heat_sch] = nil
      tstat_info[:cool_sch] = nil
    end
    tstat_groups << tstat_info
  end
  return tstat_groups
end

def add_entry(hash, list)
  new_hash = {}
  new_hash[:heat_sch] = hash[:heat_sch]
  new_hash[:cool_sch] = hash[:cool_sch]
  new_hash[:zone_names] = [hash[:zone_name]]
  list << new_hash
end

def tstat_zone_list(model)
  list = check_tstat_schedules(model)
  new_list = []
  list.each do |hash|
    if new_list.size == 0
      add_entry(hash, new_list)
    else
      new_list.each do |new_hash|
        if new_hash[:heat_sch] == hash[:heat_sch] && new_hash[:cool_sch] == hash[:cool_sch]
          new_hash[:zone_names] << hash[:zone_name]
        else
          add_entry(hash, new_list)
        end
      end
    end
  end
  return new_list
end

# tstat_zone_list(model)

def schedule_min_max_values(schedule)
  std = Standard.build("90.1-2004")
  result = nil
  if schedule.to_ScheduleRuleset.is_initialized
    result = std.schedule_ruleset_annual_min_max_value(schedule.to_ScheduleRuleset.get)
  elsif schedule.to_ScheduleConstant.is_initialized
    result = std.schedule_constant_annual_min_max_value(schedule.to_ScheduleConstant.get)
  elsif schedule.to_ScheduleCompact.is_initialized
    result = std.schedule_compact_annual_min_max_value(schedule.to_ScheduleCompact.get)
  end
  return result
end


def info_from_tstats(model)
  # returns hash of thermostat setpoint schedules, the zones assigned and the min/max setpoint values
  all_info = []
  model.getThermostatSetpointDualSetpoints.each do |stat|
    if stat.heatingSetpointTemperatureSchedule.is_initialized
      htg_sch = stat.heatingSetpointTemperatureSchedule.get
    end
    if stat.coolingSetpointTemperatureSchedule.is_initialized
      clg_sch = stat.coolingSetpointTemperatureSchedule.get
    end
    if stat.thermalZone.is_initialized
      zone = stat.thermalZone.get
    end

    result = all_info.select{|h| h[:heat_sch] == htg_sch && h[:cool_sch] == clg_sch}
    if result.empty?
      all_info << {heat_sch: htg_sch, cool_sch: clg_sch, zone_names: [zone.name.get]}
    else
      entry = result.first
      entry[:zone_names] << zone.name.get
    end
  end

  std = Standard.build("90.1-2004")

  all_info.each do |h|
    heat_temps = schedule_min_max_values(h[:heat_sch])
    h[:heat_min_temp] = heat_temps['min']
    h[:heat_max_temp] = heat_temps['max']
    cool_temps = schedule_min_max_values(h[:cool_sch])
    h[:cool_min_temp] = cool_temps['min']
    h[:cool_max_temp] = cool_temps['max']
  end

  return all_info
end

def times_from_sch(schedule)
  # returns array of [time, value] pairs in a given default day schedule
  times = []
  if schedule.to_ScheduleRuleset.is_initialized
    schedule = schedule.to_ScheduleRuleset.get
  else return false
  end
  day = schedule.defaultDaySchedule
  os_times = day.times
  os_vals = day.values
  os_times.each_with_index do |t,i|
    times << [t.to_s, os_vals[i]]
  end
  return times

end 

def string_to_os_time(str)
  # str = "18:00:00"
  hms = str.split(":").map{|i| i.to_i}
  if !hms.size == 3
    puts "WARNING: String in string_to_os_time not formatted as expected"
  end

  os_time = OpenStudio::Time.new(0,hms[0], hms[1], hms[2])
  return os_time
end

def tstat_schedule_shift(schedule, temp_shift, start_shift)
  if schedule.to_ScheduleRuleset.is_initialized
    schedule = schedule.to_ScheduleRuleset.get
  else return false
  end

  day = schedule.defaultDaySchedule
  os_times = day.times
  os_vals = day.values
  timevals = []
  os_times.each_with_index {|t,i| timevals << [t, os_vals[i]]}

  if timevals.size > 1
    occ_start_time = timevals[0][0]
    start_shift_os = string_to_os_time("#{start_shift}:00:00")
    shifted_start = occ_start_time - start_shift_os
    setback_t = timevals[0][1]
    shifted_setback = setback_t + temp_shift
  else 
    # schedule does not set back
    # register error
  end

  day.removeValue(occ_start_time)
  day.addValue(shifted_start,setback_t)
  day.addValue(occ_start_time,shifted_setback)

  return schedule

end



cool_temp_shift = 2
heat_temp_shift = 2.5
start_hour_shift = 2
end_hour_shift = 2

model = load_test_model
data = info_from_tstats(model)
data.each do |hash|
  # occ deadband
  db = hash[:cool_min_temp] - hash[:heat_max_temp]
  puts "Occupied Temp Deadband: #{db}"

  htg_sch = hash[:heat_sch]

  # times = times_from_sch(htg_sch)
  # if times.size > 1
  #   occ_start_time = times[1][0]
  #   shifted_start = occ_start_time - start_hour_shift
  #   setback_t = times[0][1]
  #   shifted_setback = setback_t + heat_temp_shift
  # else

  
  puts times_from_sch(htg_sch) 
  puts "-----------"
  tstat_schedule_shift(htg_sch, heat_temp_shift, start_hour_shift)

  puts times_from_sch(htg_sch)

end

# pp info_from_tstats(model)    

require 'pp'


# from OsLib_Schedules
# create a complex ruleset schedule
def createComplexSchedule(model, options = {})
  defaults = {
    'name' => nil,
    'default_day' => ['always_on', [24.0, 1.0]]
  }

  # merge user inputs with defaults
  options = defaults.merge(options)

  # ScheduleRuleset
  sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
  if options.keys.include? 'name'
    sch_ruleset.setName(options['name'])
  end

  # Winter Design Day
  unless options['winter_design_day'].nil?
    winter_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
    sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
    winter_dsn_day = sch_ruleset.winterDesignDaySchedule
    winter_dsn_day.setName("#{sch_ruleset.name} Winter Design Day")
    options['winter_design_day'].each do |data_pair|
      hour = data_pair[0].truncate
      min = ((data_pair[0] - hour) * 60).to_i
      winter_dsn_day.addValue(OpenStudio::Time.new(0, hour, min, 0), data_pair[1])
    end
  end

  # Summer Design Day
  unless options['summer_design_day'].nil?
    summer_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
    sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
    summer_dsn_day = sch_ruleset.summerDesignDaySchedule
    summer_dsn_day.setName("#{sch_ruleset.name} Summer Design Day")
    options['summer_design_day'].each do |data_pair|
      hour = data_pair[0].truncate
      min = ((data_pair[0] - hour) * 60).to_i
      summer_dsn_day.addValue(OpenStudio::Time.new(0, hour, min, 0), data_pair[1])
    end
  end

  # Default Day
  default_day = sch_ruleset.defaultDaySchedule
  default_day.setName("#{sch_ruleset.name} #{options['default_day'][0]}")
  default_data_array = options['default_day']
  default_data_array.delete_at(0)
  default_data_array.each do |data_pair|
    hour = data_pair[0].truncate
    min = ((data_pair[0] - hour) * 60).to_i
    default_day.addValue(OpenStudio::Time.new(0, hour, min, 0), data_pair[1])
  end

  # Rules
  unless options['rules'].nil?
    options['rules'].each do |data_array|
      rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
      rule.setName("#{sch_ruleset.name} #{data_array[0]} Rule")
      date_range = data_array[1].split('-')
      start_date = date_range[0].split('/')
      end_date = date_range[1].split('/')
      rule.setStartDate(model.getYearDescription.makeDate(start_date[0].to_i, start_date[1].to_i))
      rule.setEndDate(model.getYearDescription.makeDate(end_date[0].to_i, end_date[1].to_i))
      days = data_array[2].split('/')
      rule.setApplySunday(true) if days.include? 'Sun'
      rule.setApplyMonday(true) if days.include? 'Mon'
      rule.setApplyTuesday(true) if days.include? 'Tue'
      rule.setApplyWednesday(true) if days.include? 'Wed'
      rule.setApplyThursday(true) if days.include? 'Thu'
      rule.setApplyFriday(true) if days.include? 'Fri'
      rule.setApplySaturday(true) if days.include? 'Sat'
      rule.setApplyWeekdays(true) if days.include? 'Wkdy'
      rule.setApplyWeekends(true) if days.include? 'Wknd'
      day_schedule = rule.daySchedule
      day_schedule.setName("#{sch_ruleset.name} #{data_array[0]}")
      data_array.delete_at(0)
      data_array.delete_at(0)
      data_array.delete_at(0)
      data_array.each do |data_pair|
        hour = data_pair[0].truncate
        min = ((data_pair[0] - hour) * 60).to_i
        day_schedule.addValue(OpenStudio::Time.new(0, hour, min, 0), data_pair[1])
      end
    end
  end

  result = sch_ruleset
  return result
end

# this is a test to re-create the TOU schedule used in the tariff objects as a ScheduleRuleset (might be useful)
def create_tou_sch(model)
  ruleset_name = "SCE GS TOD Sch"
  winter_design_day = nil
  summer_design_day = nil
  rules = []
  rules << ['Weekday', '6/1-9/30', 'Wkdy', [16.00,3],[21.00,1],[24.00,3]]
  rules << ['Weekend', '6/1-9/30', 'Wknd', [16.00,3],[21.00,4],[24.00,3]]
  default_day = ['All Days', [8.00,3],[16.00,2],[21.00,4],[24.00,3]]

  options = {
    'name' => ruleset_name,
    'winter_design_day' => winter_design_day,
    'summer_design_day' => summer_design_day,
    'default_day' => default_day,
    'rules' => rules
  }
  sch = createComplexSchedule(model, options)

  return sch
end

# model = OpenStudio::Model::Model.new
# create_tou_sch(model)
# puts model
# ft = OpenStudio::EnergyPlus::ForwardTranslator.new()
# ws = ft.translateModel(model)
# puts ws