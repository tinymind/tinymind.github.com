#
# post_original_block_filter.rb
# Append author and copyright block to the end of every post
# lslin
# 2013.12.05
#
require './plugins/post_filters'

module AppendOriginBlockFilter
  def append(post)
     author = post.site.config['author']
     url = post.site.config['url']
     ob_prefix = post.site.config['original_block_prefix']
     ob_author = post.site.config['original_block_author']
     ob_copyright = post.site.config['original_block_copyright']
	 post.content + %Q[<blockquote class='post_original_block'>
            #{ob_author or "Written by: "}
			<a href='#{url}'>#{author}</a><br/>
		    #{ob_prefix or "Original link: "}
            <a href='#{post.full_url}'>#{post.full_url}</a><br/>
			#{ob_copyright}
			<a href='http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh'>(Creative Commons BY-NC-ND 3.0)</a>
            </blockquote>]
  end 
end

module Jekyll
  class AppendOriginalBlock < PostFilter
    include AppendOriginBlockFilter
    def pre_render(post)
      post.content = append(post) if post.is_post?
    end
  end
end

Liquid::Template.register_filter AppendOriginBlockFilter
