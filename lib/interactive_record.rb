require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "pragma table_info('#{table_name}')"
    db_info= DB[:conn].execute(sql)
    column_names = []
    db_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  def initialize(options={})
    options.each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col|
      values << "'#{send(col)}'" unless send(col).nil?
    end
    values.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attr)
    val = attr.values.first
    if val.class != Fixnum
      value = "'#{val}'"
    else
      value = val
    end
    sql = "SELECT * FROM #{self.table_name} WHERE #{attr.keys.first} = #{value}"
    DB[:conn].execute(sql)
  end
end
