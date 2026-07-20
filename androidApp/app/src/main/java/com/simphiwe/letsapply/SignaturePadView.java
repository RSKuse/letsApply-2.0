package com.simphiwe.letsapply;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewParent;

public final class SignaturePadView extends View {
    private final Paint strokePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint guidePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path signaturePath = new Path();
    private final Rect drawingRect = new Rect();
    private Bitmap savedSignature;
    private boolean hasSignature;
    private float lastX;
    private float lastY;

    public SignaturePadView(Context context) {
        super(context);
        setFocusable(true);
        setFocusableInTouchMode(true);
        setBackgroundColor(Color.WHITE);
        strokePaint.setColor(Color.BLACK);
        strokePaint.setStyle(Paint.Style.STROKE);
        strokePaint.setStrokeCap(Paint.Cap.ROUND);
        strokePaint.setStrokeJoin(Paint.Join.ROUND);
        strokePaint.setStrokeWidth(6f);

        guidePaint.setColor(Color.rgb(216, 230, 222));
        guidePaint.setStyle(Paint.Style.STROKE);
        guidePaint.setStrokeWidth(2f);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (savedSignature != null && !savedSignature.isRecycled()) {
            getDrawingRect(drawingRect);
            canvas.drawBitmap(savedSignature, null, drawingRect, null);
        }

        canvas.drawPath(signaturePath, strokePaint);
        float baseline = getHeight() - 34f;
        canvas.drawLine(36f, baseline, getWidth() - 36f, baseline, guidePaint);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        float x = event.getX();
        float y = event.getY();
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                requestParentScroll(false);
                savedSignature = null;
                signaturePath.moveTo(x, y);
                lastX = x;
                lastY = y;
                hasSignature = true;
                invalidate();
                return true;
            case MotionEvent.ACTION_MOVE:
                requestParentScroll(false);
                float dx = Math.abs(x - lastX);
                float dy = Math.abs(y - lastY);
                if (dx >= 2f || dy >= 2f) {
                    signaturePath.quadTo(lastX, lastY, (x + lastX) / 2f, (y + lastY) / 2f);
                    lastX = x;
                    lastY = y;
                }
                invalidate();
                return true;
            case MotionEvent.ACTION_UP:
                signaturePath.lineTo(x, y);
                requestParentScroll(true);
                invalidate();
                return true;
            case MotionEvent.ACTION_CANCEL:
                requestParentScroll(true);
                invalidate();
                return true;
            default:
                return true;
        }
    }

    private void requestParentScroll(boolean allow) {
        ViewParent parent = getParent();
        while (parent != null) {
            parent.requestDisallowInterceptTouchEvent(!allow);
            parent = parent.getParent();
        }
    }

    public void clearSignature() {
        signaturePath.reset();
        savedSignature = null;
        hasSignature = false;
        invalidate();
    }

    public boolean hasSignature() {
        return hasSignature || savedSignature != null;
    }

    public Bitmap signatureBitmap() {
        Bitmap bitmap = Bitmap.createBitmap(getWidth(), getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        draw(canvas);
        return bitmap;
    }

    public void loadSignature(Bitmap bitmap) {
        savedSignature = bitmap;
        hasSignature = bitmap != null;
        signaturePath.reset();
        invalidate();
    }
}
