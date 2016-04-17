class Racer
  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def initialize(attributes = {})
    @id         = attributes[:_id].nil? ? attributes[:id] : attributes[:_id].to_s
    @number     = attributes[:number].to_i
    @first_name = attributes[:first_name]
    @last_name  = attributes[:last_name]
    @gender     = attributes[:gender]
    @group      = attributes[:group]
    @secs       = attributes[:secs].to_i
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    mongo_client[:racers]
  end

  def self.all(prototype = {}, sort = { number: 1 }, skip = 0, limit = nil)
    query = collection.find(prototype).skip(skip)
    query = query.sort(sort) if sort.present?
    query = query.limit(limit) if limit.present?
    query
  end

  def self.find(id)
    id = BSON::ObjectId.from_string(id.to_s)
    result = collection.find('_id' => id).first
    return result.nil? ? nil : Racer.new(result)
  end

  def save
    doc = { number: @number, first_name: @first_name, last_name: @last_name, gender: @gender, group: @group, secs: @secs }
    result = self.class.collection.insert_one(doc)
    @id = result.inserted_id.to_s
  end

  def update(attributes)
    @number = attributes[:number].to_i
    @first_name = attributes[:first_name]
    @last_name = attributes[:last_name]
    @secs = attributes[:secs].to_i
    @gender = attributes[:gender]
    @group = attributes[:group]
    attributes.slice!(:number, :first_name, :last_name, :gender, :group, :secs)
    self.class.collection.find('_id' => BSON::ObjectId.from_string(@id)).update_one(attributes)
  end

  def destroy
    self.class.collection.delete_one('_id' => BSON::ObjectId.from_string(@id))
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  def self.paginate(params)
    page = (params[:page] || 1).to_i
    limit = (params[:per_page] || 30).to_i
    skip = (page - 1) * limit
    racers = []
    all({}, { number: 1 }, skip, limit).each { |racer| racers << new(racer) }
    total = collection.count
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end
  end

end