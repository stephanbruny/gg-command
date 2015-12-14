using Gtk;
using GLib;
using Cairo;


class ImageButton : Gtk.Button {
	private Cairo.ImageSurface surface;
	private double size = 24;
	private bool entered = false; 
	public delegate void OnClick();

	private OnClick onClick;

	public ImageButton(string path, double size, OnClick click) {
		this.size = size;
		this.onClick = click;
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
		return true;
	}
}

class TimeTasklet : Gtk.Button {
	private DateTime now = new DateTime.now_local();

	private double width = 128.0;
	private int fontSize = 12;
	private double height;

	public TimeTasklet(double height) {
		this.height = height;
		Timeout.add(1000, () => { this.now = new DateTime.now_local(); this.queue_draw(); return true; });
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

	public GgCommand(int height = 24) {
		Gdk.Window rootWin = Gdk.get_default_root_window();
		this.width = rootWin.get_width();
		this.height = height;
		this.set_default_size(width, height);
		this.set_keep_above(true);
		this.set_resizable(false);
		this.move(0, 0);
		this.decorated = false;
		this.set_type_hint(Gdk.WindowTypeHint.DOCK);
		this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, this.width, this.height);
		this.create_widgets();
		this.queue_draw();
	}

	private void create_widgets() {
		var area = new Box(Gtk.Orientation.HORIZONTAL, 0);
		area.set_size_request(this.width, this.height);
		area.draw.connect(on_draw);
		var systemIconBox = new Box(Gtk.Orientation.HORIZONTAL, 0);
		var taskletIconBox = new Box(Gtk.Orientation.HORIZONTAL, 0);
		area.add(systemIconBox);
		area.add(taskletIconBox);
	
		var button = new ImageButton(iconPath + "/GRID.svg", this.height, () => {});
		button.has_tooltip = true;
		button.set_tooltip_markup("<b>Grid</b>");
		var button2 = new ImageButton(iconPath + "/WIFI.svg", this.height, () => {});
		button2.has_tooltip = true;
		button2.set_tooltip_markup("<b>WIFI enabled</b>");
		systemIconBox.add(new ImageButton(iconPath + "/HEART.svg", this.height, () => {}));
		systemIconBox.add(new ImageButton(iconPath + "/POWER.svg", this.height, () => {
			Posix.system("shutdown now");
		}));
		systemIconBox.add(new ImageButton(iconPath + "/BROWSER.svg", this.height, () => {
			Posix.system("terminator &");
		}));
		systemIconBox.add(button);
		systemIconBox.add(button2);
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
		var self = new GgCommand(24);

		self.show_all();

		Gtk.main();
		return 0;	
	}
}
