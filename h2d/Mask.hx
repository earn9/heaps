package h2d;


class Mask extends Object {

	/**
		Masks render zone based off object position and given dimensions.
		Should call `Mask.unmask()` afterwards.
	**/
	@:access(h2d.RenderContext)
	public static function maskWith( ctx : RenderContext, object : Object, width : Int, height : Int, scrollX : Float = 0, scrollY : Float = 0) {

		var x1 = object.absX + scrollX;
		var y1 = object.absY + scrollY;

		var x2 = width * object.matA + height * object.matC + x1;
		var y2 = width * object.matB + height * object.matD + y1;

		var tmp;
		if (x1 > x2) {
			tmp = x1;
			x1 = x2;
			x2 = tmp;
		}

		if (y1 > y2) {
			tmp = y1;
			y1 = y2;
			y2 = tmp;
		}

		ctx.flush();
		ctx.pushRenderZone(x1, y1, x2-x1, y2-y1);
	}

	/**
		Unmasks prviously masked area from `Mask.maskWith`.
	**/
	public static function unmask( ctx : RenderContext ) {
		ctx.flush();
		ctx.popRenderZone();
	}

	public var width : Int;
	public var height : Int;
	var parentMask : Mask;

	/**
		Horizontal scroll offset of the Mask content in pixels. Can be clamped by `scrollBounds`.
	**/
	public var scrollX(default, set) : Float = 0;
	/**
		Vertical scroll offset of the Mask content in pixels. Can be clamped by `scrollBounds`.

	**/
	public var scrollY(default, set) : Float = 0;

	/**
		Optional scroll boundaries that prevent content from overscroll.
	**/
	public var scrollBounds : h2d.col.Bounds;

	public function new(width, height, ?parent) {
		super(parent);
		this.width = width;
		this.height = height;
	}

	/**
		Scroll Mask content to specified offset.
	**/
	public function scrollTo( x : Float, y : Float ) {
		scrollX = x;
		scrollY = y;
	}

	/**
		Scroll Mask content by specified offset relative to current scroll offset.
	**/
	public function scrollBy( x : Float, y : Float ) {
		scrollX += x;
		scrollY += y;
	}

	override private function onHierarchyMoved(parentChanged:Bool) {
		super.onHierarchyMoved(parentChanged);
		if ( parentChanged )
			updateMask();
	}

	override function onAdd() {
		super.onAdd();
		updateMask();
	}

	function updateMask() {
		parentMask = null;
		var p = parent;
		while( p != null ) {
			var m = hxd.impl.Api.downcast(p, Mask);
			if( m != null ) {
				parentMask = m;
				break;
			}
			p = p.parent;
		}
	}

	function set_scrollX( v : Float ) : Float {
		if ( scrollBounds != null ) v = hxd.Math.clamp(v, scrollBounds.xMin, scrollBounds.xMax - width);
		posChanged = true;
		return scrollX = v;
	}

	function set_scrollY( v : Float ) : Float {
		if ( scrollBounds != null ) v = hxd.Math.clamp(v, scrollBounds.yMin, scrollBounds.yMax - height);
		posChanged = true;
		return scrollY = v;
	}

	override function calcAbsPos()
	{
		super.calcAbsPos();
		absX -= scrollX;
		absY -= scrollY;
	}

	override function getBoundsRec( relativeTo, out:h2d.col.Bounds, forSize ) {
		var xMin = out.xMin, yMin = out.yMin, xMax = out.xMax, yMax = out.yMax;
		out.empty();
		if( posChanged ) {
			calcAbsPos();
			for( c in children )
				c.posChanged = true;
			posChanged = false;
		}
		addBounds(relativeTo, out, scrollX, scrollY, width, height);
		var bxMin = out.xMin, byMin = out.yMin, bxMax = out.xMax, byMax = out.yMax;
		out.xMin = xMin;
		out.xMax = xMax;
		out.yMin = yMin;
		out.yMax = yMax;
		super.getBoundsRec(relativeTo, out, forSize);
		if( out.xMin < bxMin ) out.xMin = hxd.Math.min(xMin, bxMin);
		if( out.yMin < byMin ) out.yMin = hxd.Math.min(yMin, byMin);
		if( out.xMax > bxMax ) out.xMax = hxd.Math.max(xMax, bxMax);
		if( out.yMax > byMax ) out.yMax = hxd.Math.max(yMax, byMax);
	}

	override function drawRec( ctx : h2d.RenderContext ) @:privateAccess {
		maskWith(ctx, this, width, height, scrollX, scrollY);
		super.drawRec(ctx);
		unmask(ctx);
	}

}