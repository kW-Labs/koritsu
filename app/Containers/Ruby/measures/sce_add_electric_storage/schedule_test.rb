require 'openstudio'
def parse_time_range(range_string)
  hours = []
  minutes = []
  data = range_string.split(/[-:]/)
  data.each {|e| e.delete!(' ')}
  if data[2] > data[0]
    hours << data[0] << data[2]
    minutes << data[1] << data[3]
  else
    hours << data[2] << data[0] << 24
    minutes << data[3] << data[1] << 0
  end
  
  return hours, minutes
end

def os_times_from_string(range_string)
  hours, minutes = parse_time_range(range_string)
  times = []
  hours.each_with_index do |h,i|
    times << OpenStudio::Time.new(0,h.to_i,minutes[i].to_i)
  end
  puts times
  return times
end

def self.get_fraction(model)
  name = "FRACTION"
  fraction_schedule_type_limits = model.getScheduleTypeLimitsByName(name)
  if fraction_schedule_type_limits.empty?
    fraction_schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    fraction_schedule_type_limits.setName(name)
    fraction_schedule_type_limits.setNumericType("CONTINUOUS")
    fraction_schedule_type_limits.setUnitType("Dimensionless")
    fraction_schedule_type_limits.setLowerLimitValue(0.0)
    fraction_schedule_type_limits.setUpperLimitValue(1.0)
    return fraction_schedule_type_limits
  else
    return fraction_schedule_type_limits.get
  end
end

def create_charge_fraction_schedule(model, times)
  sch = OpenStudio::Model::ScheduleRuleset.new(model, 0)
  sch.setName("Charge Fraction Schedule")
  sch.setScheduleTypeLimits(get_fraction(model))
  d_day = sch.defaultDaySchedule
  times.each_with_index do |time, i|
    # even number of times 
    if times.size.even?
      i % 2 == 1 ? v = 1 : v = 0
      d_day.addValue(time, v)
    else
      # i & 1 == 1 ? v = 0 : v = 1
      i % 2 == 1 ? v = 0 : v = 1
      d_day.addValue(time, v)
    end
  end
  return sch
end

def invert_schedule(model, sch)
  # clone sch
  new_sch = sch.clone(model).to_ScheduleRuleset.get
  old_vals = sch.defaultDaySchedule.values
  old_times = sch.defaultDaySchedule.times
  old_times.each_with_index do |t,i|
    # XOR old value (0 or 1) to get new value (1 or 0)
    new_sch.defaultDaySchedule.addValue(t, old_vals[i].to_i ^ 1)
  end
  return new_sch
end


test_string = "00:10 - 23:29"
# test_string = "20:00 - 04:00"
test_string = "00:00 - 06:00"
times = os_times_from_string(test_string)
model = OpenStudio::Model::Model.new
sch = create_charge_fraction_schedule(model, times)
# puts "Hours: #{hours}"
# puts "Minutes: #{minutes}"

puts sch.defaultDaySchedule

new_sch = invert_schedule(model, sch)
puts new_sch.defaultDaySchedule
puts new_sch.scheduleTypeLimits.get