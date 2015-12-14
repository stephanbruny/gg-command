using Gtk;
using GLib;
using Cairo;


class ImageButton : Gtk.Button {
	private Cairo.ImageSurface surface;
	private double size = 24;
	private bool entered = false; 
	public delegate void OnClick();

	public OnClick onClick;

	public ImageButton(string path, double size) {
		this.size = size;
		this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, (int)size, (int)size);
		this.set_app_paintable(false);
		stdout.printf(path + "\n");
		stdout.flush();
		var ctx = new Cairo.Context(this.surface);
		ctx.set_antialias(Cairo.Antialias.SUBPIXEL);
		Rsvg.Handle handle = new Rsvg.Handle.from_file(path);
		ctx.save();
		ctx.scale(size / handle.width, size / handle.height);
		handle.render_cairo(ctx);
		ctx.restore();
		this.set_size_request((int)size, (int)size);

		this.enter_notify_event.connect(() => {
			this.entered = true;
			this.queue_draw();	
			return false;	
		});

		this.leave_notify_event.connect(() => {
			this.entered = false;	
			this.queue_draw();
			return false;
		});
		
		this.clicked.connect(() => {
			this.onClick();
		});
	}

	private void draw_background(Cairo.Context ctx) {
		ctx.rectangle(0, 0, this.size, this.size);
		ctx.set_source_rgba(0, 0, 0, 0);
		ctx.set_operator(Cairo.Operator.SOURCE);
		ctx.paint();
		ctx.fill();
	}

	private void draw_background_active(Cairo.Context ctx) {
		ctx.set_operator(Cairo.Operator.SOFT_LIGHT);
		Cairo.Pattern pattern = new Cairo.Pattern.linear(0, 0, 0, this.size);
		pattern.add_color_stop_rgba(0, 0.3, 1, 0.3, 0.9);
		pattern.add_color_stop_rgba(1, 0.3, 0.3, 1, 0.5);
		ctx.rectangle(0, 0, this.size, this.size);
		ctx.set_source(pattern);
		ctx.fill();
		ctx.paint();
	}

	public override bool draw(Cairo.Context ctx) {
		ctx.save();
		ctx.set_antialias(Cairo.Antialias.SUBPIXEL);
		// this.draw_background(ctx);
		ctx.set_source_surface(this.surface, 0, 0);
		ctx.paint();
		if (this.entered) {
			draw_background_active(ctx);
		}
		ctx.restore();
		return false;
	}
}

class TimeTasklet : Gtk.Button {
	private DateTime now = new DateTime.now_local();

	private double width = 128.0;
	private int fontSize = 12;
	private double height;

	public TimeTasklet(double height) {
		this.height = height;
		Timeout.add(1000, () => { 
			this.now = new DateTime.now_local(); 
			this.queue_draw();
			this.set_tooltip_markup(this.now.format("%x")); 
			return true; 
		});
		this.set_size_request((int)this.width, (int)this.height);
	}

	public override bool draw(Cairo.Context ctx) {
		// ctx.save();
		ctx.set_antialias(Cairo.Antialias.SUBPIXEL);
		ctx.select_font_face("Ubuntu", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		ctx.set_font_size(this.fontSize);

		string text = this.now.format("%A %H:%M");

		Cairo.TextExtents ext;
		ctx.text_extents(text, out ext);
		double x = this.width / 2 - ext.width/2;
		double y = this.height / 2 + ext.height/2;
		ctx.move_to(x, y + 1);
		ctx.set_source_rgb(1, 1, 1);
		ctx.show_text(text);

		ctx.move_to(x, y);
		ctx.set_source_rgb(0.1, 0.1, 0.1);
		ctx.show_text(text);
		// ctx.paint();
		// ctx.restore();
		return true;
	}
}

class GgCommand : Gtk.Window {

	const string iconPath = "/home/odroid/Pictures/Icons/SVG";

	int width = 1024;
	int height = 768;

	private Cairo.ImageSurface surface;

	string configPath;

	public GgCommand(int height = 24, string jsonConfigPath) {
		Gdk.Window rootWin = Gdk.get_default_root_window();
		this.configPath = jsonConfigPath;
		this.width = rootWin.get_width();
		this.height = height;
		this.set_default_size(width, height);
		this.set_keep_above(true);
		this.set_resizable(false);
		this.move(0, 0);
		this.decorated = false;
		this.set_type_hint(Gdk.WindowTypeHint.DOCK);
		this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, this.width, this.height);
		this.create_widgets(this.configPath);
		this.queue_draw();
	}

	private void load_tasklets_from_json(string path, Box taskletBox) {
		Json.Parser parser = new Json.Parser();
		try {
			parser.load_from_file(path);		
		} catch (Error err) {
			stderr.printf(err.message + "\n");
		}
		var root = parser.get_root().get_object();
		var tasklets = root.get_array_member("tasklets");
		foreach (var taskletConf in tasklets.get_elements()) {
			try {
				var tasklet = taskletConf.get_object();
				var widget = new ImageButton(iconPath + "/" + tasklet.get_string_member("icon"), this.height);
				widget.onClick = () => {
					Posix.system(tasklet.get_string_member("command"));
				};
				// widget.set_tooltip_markup(tasklet.get_string_member("tooltip"));
				widget.has_tooltip = true;
				taskletBox.add(widget);
			} catch (Error err) {
				stderr.printf(err.message + "\n");
			}
		}
		
	}

	private void create_widgets(string configPath) {
		var area = new Box(Gtk.Orientation.HORIZONTAL, 0);
		area.set_size_request(this.width, this.height);
		area.draw.connect(on_draw);
		var systemIconBox = new Box(Gtk.Orientation.HORIZONTAL, 0);
		var taskletIconBox = new Box(Gtk.Orientation.HORIZONTAL, 0);
		area.add(systemIconBox);
		area.add(taskletIconBox);
	
		load_tasklets_from_json(configPath, systemIconBox);
		
		systemIconBox.set_size_request(this.width / 2, this.height);

		taskletIconBox.set_halign(Align.END);
		taskletIconBox.add(new TimeTasklet(this.height));
		taskletIconBox.set_size_request(this.width / 2, this.height);

		area.set_halign(Align.CENTER);
		this.add(area);	
	}

	private bool on_draw (Widget widget, Context ctx) {
		ctx.save();	
		// ctx.set_source_surface(this.surface, 0, 0);
		ctx.set_operator(Cairo.Operator.SOURCE);
		ctx.set_source_rgba(1, 1, 1, 0.8);
		ctx.rectangle(0, 0, this.width, this.height);
		ctx.fill();
		ctx.move_to(0, this.height);
		ctx.rel_line_to(this.width, 0);
		ctx.set_line_width(2);
		ctx.set_source_rgba(1, 1, 1, 1);
		ctx.stroke();
		// ctx.paint();
		ctx.restore();
		widget.queue_draw();
		return false;
	}

	static int main(string[] args) {	
		Gtk.init(ref args);
		var self = new GgCommand(24, "./ApplicationData/config.json");

		self.show_all();

		Gtk.main();
		return 0;	
	}
}
