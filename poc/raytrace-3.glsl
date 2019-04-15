
#define PI 3.141592653

// If it doesn't work, here's the checklist:

// 1. getRay function, check vector subtractions
// 2. intersectEllipsoid function, check matrix mult order
// 3. intersectEllipsoid function, check matrices

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

struct Material {
	bool reflective;
	vec3 diffuse;
	vec3 n;
	vec3 k;
};
	
struct Ellipsoid {
	vec3 center;
	vec3 radius;
	int materialId;
};
    
struct Sphere {
    vec3 center;
    float radius;
    int materialId;
};
	
struct Ray {
	vec3 origin;
	vec3 direction;
};

struct Hit {
	bool didHit;
	vec3 rayOrigin;
	vec3 rayDirection;
	vec3 hitPoint;
	vec3 hitNormal;
	int hitMaterialId;
    float hitDistance;
};
    
struct Plane {
    vec3 point;
    vec3 normal;
};
	
const int numMirrorSides = 10;
const vec3 lightDir = normalize (vec3 (0.0, 0.0, -1.0));
const vec3 lightAmbient = vec3 (0.1, 0.1, 0.1);
const vec3 lightEnergy = vec3 (1.0, 0.8, 1.0);
const vec3 cameraDir = normalize (vec3 (0.0, 0.0, 1.0));
const vec3 cameraEyePoint = vec3 (0.0, 0.0, -6.0);

// TODO: Implement proper camera

const Material diffuseMaterial = Material (false, vec3(1.0, 0.0, 0.0), vec3(0.0), vec3(0.0));
const Material goldMaterial = Material(true, vec3(0.0), vec3 (0.17, 0.35, 1.5), vec3 (3.1, 2.7, 1.9));
const Material silverMaterial = Material(true, vec3(0.0), vec3 (0.14, 0.16, 0.13), vec3 (4.1, 2.3, 3.1));

const Material [] MATERIALS = Material [] ( diffuseMaterial, goldMaterial, silverMaterial );

const Ellipsoid [] ELLIPSOIDS = Ellipsoid [] (
    Ellipsoid (vec3 (-1.5, 0.6, 5.2), vec3 (0.3, 0.35, 0.1), 1),
    Ellipsoid (vec3 (1.2, -0.9, 5.0), vec3 (0.18, 0.2, 0.3), 1)
);

const Sphere [] spheres = Sphere [] (
    Sphere (vec3 (-1.5, 0.6, 5.2), 0.2, 0),
    Sphere (vec3 (1.2, -0.9, 5.0), 0.3, 0)
);
const int numSpheres = 2;

Material getMaterialById (int id) {
	if (id == 0) return diffuseMaterial;
	if (id == 1) return goldMaterial;
	return silverMaterial;
}

void intersectSphere (in Ray ray, in Sphere sphere, out Hit hit) {
    
    hit.rayOrigin = ray.origin;
    hit.rayDirection = ray.direction;
    
    vec3 dist = ray.origin - sphere.center;
    
    float a = dot (ray.direction, ray.direction);
    float b = dot (dist, ray.direction) * 2.0;
    float c = dot (dist, dist) - sphere.radius * sphere.radius;
    float discr = b * b - 4.0 * a * c;
    
    if (discr < 0.0) {
        hit.didHit = false;
        return;
    }
    
    float sqrt_discr = sqrt (discr);
    float t1 = (-b + sqrt_discr) / 2.0 / a;
    float t2 = (-b - sqrt_discr) / 2.0 / a;
    
    if (t1 <= 0.0) {
        hit.didHit = false;
        return;
    }
    
    float hitT = (t2 > 0.0) ? t2 : t1;
    
    hit.didHit = true;
    hit.hitPoint = ray.origin + ray.direction * hitT;
    hit.hitNormal = normalize ((hit.hitPoint - sphere.center));
    hit.hitMaterialId = sphere.materialId;
    hit.hitDistance = hitT;
    
}

void intersectEllipsoid (in Ray ray, in Ellipsoid ellipsoid, out Hit hit) {
    
    
    
}

void intersectPlane (in Ray ray, in Plane plane, out Hit hit) {
    
    hit.rayOrigin = ray.origin;
    hit.rayDirection = ray.direction;
    
    float denom = dot(plane.normal, ray.direction);
    if (denom > 0.001) {
        vec3 p010 = plane.point - ray.origin;
        float t = dot (p010, plane.normal) / denom;
        
        if (t > 0.0) {
            
            hit.didHit = true;
            hit.hitPoint = ray.origin + ray.direction * t;
            hit.hitDistance = t;
            hit.hitMaterialId = 2;
            hit.hitNormal = normalize (plane.normal);
            
        } else {
            hit.didHit = false;
        }
    }
    
}

void intersectMirrors (in Ray ray, out Hit hit) {
    
    Hit bestHit;
    float angle = 2.0 * PI / float (numMirrorSides);
    for (int i = 0; i < numMirrorSides; i++) {
        
        vec3 p1 = vec3 (cos (float (i) * angle), sin (float (i) * angle), 0.0) * 10.0;
        vec3 p2 = vec3 (cos (float (i + 1) * angle), sin (float (i + 1) * angle), 0.0) * 10.0;
        vec3 p1p2 = p2 - p1;
        vec3 v = vec3 (0.0, 0.0, 1.0);
        
        vec3 planeNormal = normalize (cross (normalize (p1p2), v));
        planeNormal = normalize (planeNormal);
        
        vec3 planePoint = p1;
        Plane plane = Plane (planePoint, planeNormal);
        
        Hit planeHit;
        intersectPlane (ray, plane, planeHit);
        
        if (planeHit.didHit) {
            if (!bestHit.didHit || bestHit.hitDistance >= planeHit.hitDistance) {
                bestHit = planeHit;
            }
        }
        
    }
    
    hit = bestHit;
    
}

void getRay (in vec2 pixelNdc, in float aspect, out Ray ray) {
	
	ray.origin = cameraEyePoint;
    ray.direction = normalize ( vec3 (pixelNdc.x * aspect, pixelNdc.y, 0.0) - cameraEyePoint );
    
}

void rayTrace (in Ray ray, out Hit hit) {
	
	hit.didHit = false;
	
    Hit innerHit;
    for (int i = 0; i < numSpheres; i++) {
        
        Hit currentHit;
        Sphere currentSphere = spheres [i];
        intersectSphere (ray, currentSphere, currentHit);
        
        if (currentHit.didHit) {
            if (!innerHit.didHit || innerHit.hitDistance > currentHit.hitDistance) {
                innerHit = currentHit;
            }
        }
        
    }
    
    Hit mirrorsHit;
    intersectMirrors (ray, mirrorsHit);
    
    if (mirrorsHit.didHit && (mirrorsHit.hitDistance < innerHit.hitDistance || !innerHit.didHit)) {
        innerHit = mirrorsHit;
    }
    
    hit = innerHit;
	
}

void calculateColor ( in vec2 pixelNdc, in float aspect, out vec4 finalColor ) {
    
    Ray ray;
    getRay (pixelNdc, aspect, ray);
    
    Hit hit;
    rayTrace (ray, hit);
    
    if (hit.didHit) {
        
        Material mat = MATERIALS [hit.hitMaterialId];
        
        if (mat.reflective) {
            // finalColor = vec4 (hit.hitNormal, 1.0);
            
            // Secondary ray hit
            Ray reflRay;
            reflRay.origin = hit.hitPosition + 0.001 * hit.hitNormal;
            reflRay.direction = reflect (hit.rayDirection, hit.hitNormal);
            
            Hit reflHit;
            rayTrace (reflRay, reflHit);
            
            if (reflHit.didHit) {
                
            }
            
        } else {
            vec3 color;
            float cosTheta = dot(hit.hitNormal, lightDir);
            color = lightAmbient;
            if (cosTheta > 0.0) {
                color += lightEnergy * mat.diffuse * cosTheta;
                /* vec3 halfway = normalize (-hit.rayDirection + lightDir);
                float cosDelta = dot (hit.hitNormal, halfway);
                if (cosDelta > 0.0) {
                    color += lightEnergy * mat.specular * pow(cosDelta, mat.shininess);
                } */
            }
            finalColor = vec4 (color, 1.0);
        }
        
    } else {
        finalColor = vec4 (0.0, 0.0, 0.0, 1.0);
    }
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    float aspect = iResolution.x / iResolution.y;
	vec2 pixelNdc = 2.0 * (( fragCoord.xy / iResolution.xy ) - 0.5);

	calculateColor (pixelNdc, aspect, fragColor);

}