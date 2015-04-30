class Repositories
  class Hex < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'https://hex.pm'
    COLOR = '#6e4a7e'

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("https://hex.pm/api/packages?page=#{page}")
        break if r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['name'] }
    end

    def self.recent_names
      u = 'https://hex.pm/feeds/new-packages.rss'
      titles = SimpleRSS.parse(Typhoeus.get(u).body).items.map(&:title)
      titles.map { |t| t.split('Package').last.strip.gsub('"','') }
    end

    def self.project(name)
      sleep 30
      get("https://hex.pm/api/packages/#{name}")
    end

    def self.mapping(project)
      links = project["meta"].fetch("links", {}).each_with_object({}) do |(k, v), h|
        h[k.downcase] = v
      end
      {
        :name => project["name"],
        :homepage => links.except('github').first.try(:last),
        :repository_url => links['github'],
        :description => project["meta"]["description"],
        :licenses => repo_fallback(project["meta"].fetch("licenses", []).join(','), links.except('github').first.try(:last))
      }
    end

    def self.versions(project)
      project["releases"].map do |version|
        {
          :number => version['version'],
          :published_at => version['created_at']
        }
      end
    end

    def self.dependencies(name, version)
      deps = get("https://hex.pm/api/packages/#{name}/releases/#{version}")['requirements']
      return [] if deps.nil?
      deps.map do |k, v|
        {
          project_name: k,
          requirements: v['requirement'],
          kind: 'normal',
          optional: v['optional'],
          platform: self.name.demodulize
        }
      end
    end
  end
end
