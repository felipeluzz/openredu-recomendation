module ActivityRepresenter
  include Roar::Representer::JSON
  include Roar::Representer::Feature::Hypermedia
  property :id
  property :created_at
  property :type
  property :text

  link :self do
    api_status_url self
    # polymorphic_url([:api, self])
  end

  link :statusable do
    if statusable.is_a?(User) || statusable.is_a?(Space) || statusable.is_a?(Lecture)
      polymorphic_url([:api, self.statusable])
    end
  end

  link :user do
    api_user_url(self.user)
  end

  link :answers do
    api_status_answers_url(self)
  end
end
