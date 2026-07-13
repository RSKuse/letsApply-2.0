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

public final class SignaturePadView extends View {
    private final Paint strokePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint guidePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path signaturePath = new Path();
    private final Rect drawingRect = new Rect();
    private Bitmap savedSignature;
    private boolean hasSignature;

    public SignaturePadView(Context context) {
        super(context);
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
        getParent().requestDisallowInterceptTouchEvent(true);

        float x = event.getX();
        float y = event.getY();
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                signaturePath.moveTo(x, y);
                hasSignature = true;
                invalidate();
                return true;
            case MotionEvent.ACTION_MOVE:
                signaturePath.lineTo(x, y);
                invalidate();
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                getParent().requestDisallowInterceptTouchEvent(false);
                invalidate();
                return true;
            default:
                return true;
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
