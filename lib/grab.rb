require './lib/image_grabber'

# ================Attention (this have some issues)==================
# Dont work properly with https
# Fetch only <img>, neither background(url) nor background-image(url)
#
# so works nice on sites like news.rambler.ru, lenta.ru and so on...
# ===================================================================

# exec point
ImageGrabber::Grabber.new.grab *ARGV